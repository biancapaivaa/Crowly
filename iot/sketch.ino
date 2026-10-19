#include <Arduino.h>
#include <DHTesp.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <time.h>
#include "config.h"
#include "certificates.h"

struct Botao;
// A rede roda em outra tarefa. O loop dos sensores nao aguarda HTTP/TLS.
portMUX_TYPE snapshotMutex = portMUX_INITIALIZER_UNLOCKED;
struct Snapshot {
  uint32_t entries, exits, emergency, crowding, team;
  float temperature, humidity, distance;
};
Snapshot latestSnapshot{};
uint32_t totalEntradas = 0, totalSaidas = 0;
uint32_t totalEmergencias = 0, totalAglomeracoes = 0, totalEquipes = 0;
void redeTask(void*);

// CROWLY — ESP32 DevKit C V4 / Wokwi
// Use o diagram.json corrigido: cpuFrequency = "16", DHT22 no GPIO 4,
// alimentacao direta e resistor de pull-up de 10 kohms entre SDA e 3V3.
// libraries.txt: DHT sensor library for ESPx
// HTTPS com validacao de certificado; dados vinculados pela credencial DEVICE_TOKEN.

// Contagem de pessoas
const int PIR_ENTRADA = 18;
const int PIR_SAIDA = 19;

// Estimativa de fila
const int TRIG_PIN = 5;
const int ECHO_PIN = 34;

// Botoes: pressionado = LOW (ligados ao GND)
const int BTN_EMERGENCIA = 32;
const int BTN_AGLOMERACAO = 33;
const int BTN_EQUIPE = 13;

// Indicadores
const int LED_VERDE = 25;
const int LED_AMARELO = 26;
const int LED_VERMELHO = 27;
const int BUZZER = 14;

const int DHT_PIN = 4;
DHTesp dht;

// Limites em quantidade de pessoas, nao porcentagem.
const int LIMITE_ATENCAO = 70;
const int LIMITE_CRITICO = 90;
const float FILA_MODERADA_CM = 120.0;
const float FILA_CHEIA_CM = 50.0;

const unsigned long INTERVALO_CONTAGEM = 2500;
const unsigned long INTERVALO_DHT = 2500;
const unsigned long INTERVALO_ULTRASSOM = 300;
const unsigned long INTERVALO_RELATORIO = 3000;
const unsigned long DEBOUNCE_MS = 40;

int pessoas = 0;
int estadoEntradaAnterior = LOW;
int estadoSaidaAnterior = LOW;
unsigned long ultimaEntrada = 0;
unsigned long ultimaSaida = 0;
bool contouEntrada = false;
bool contouSaida = false;

bool emergencia = false;
bool aglomeracao = false;
bool equipe = false;
float temperatura = NAN;
float umidade = NAN;
float distancia = NAN;
String estadoFila = "Indeterminada";

unsigned long ultimaLeituraDHT = 0;
unsigned long ultimaLeituraUltrassom = 0;
unsigned long ultimoRelatorio = 0;

struct Botao {
  explicit Botao(int gpio) : pino(gpio) {}
  int pino;
  bool ultimaLeitura = false;
  bool pressionado = false;
  unsigned long mudouEm = 0;
};
Botao botaoEmergencia{BTN_EMERGENCIA};
Botao botaoAglomeracao{BTN_AGLOMERACAO};
Botao botaoEquipe{BTN_EQUIPE};

void configurarGPIO() {
  pinMode(PIR_ENTRADA, INPUT);
  pinMode(PIR_SAIDA, INPUT);
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(BTN_EMERGENCIA, INPUT_PULLUP);
  pinMode(BTN_AGLOMERACAO, INPUT_PULLUP);
  pinMode(BTN_EQUIPE, INPUT_PULLUP);
  pinMode(LED_VERDE, OUTPUT);
  pinMode(LED_AMARELO, OUTPUT);
  pinMode(LED_VERMELHO, OUTPUT);
  pinMode(BUZZER, OUTPUT);
  digitalWrite(TRIG_PIN, LOW);
  digitalWrite(LED_VERDE, LOW);
  digitalWrite(LED_AMARELO, LOW);
  digitalWrite(LED_VERMELHO, LOW);
  digitalWrite(BUZZER, LOW);
}

void atualizarContagem() {
  const unsigned long agora = millis();
  const int entrada = digitalRead(PIR_ENTRADA);
  const int saida = digitalRead(PIR_SAIDA);

  if (entrada == HIGH && estadoEntradaAnterior == LOW &&
      (!contouEntrada || agora - ultimaEntrada >= INTERVALO_CONTAGEM)) {
    pessoas++;
    totalEntradas++;
    ultimaEntrada = agora;
    contouEntrada = true;
    Serial.printf("[CONTAGEM] Entrada. Total: %d\n", pessoas);
  }
  if (saida == HIGH && estadoSaidaAnterior == LOW &&
      (!contouSaida || agora - ultimaSaida >= INTERVALO_CONTAGEM)) {
    if (pessoas > 0) pessoas--;
    totalSaidas++;
    ultimaSaida = agora;
    contouSaida = true;
    Serial.printf("[CONTAGEM] Saida. Total: %d\n", pessoas);
  }
  estadoEntradaAnterior = entrada;
  estadoSaidaAnterior = saida;
}

void atualizarFila() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  const unsigned long duracao = pulseIn(ECHO_PIN, HIGH, 30000);
  if (duracao == 0) {
    distancia = NAN;
    estadoFila = "Sem leitura";
    return;
  }
  distancia = duracao * 0.0343f / 2.0f;
  if (distancia > FILA_MODERADA_CM) {
    estadoFila = "Vazia";
  } else if (distancia > FILA_CHEIA_CM) {
    estadoFila = "Moderada";
  } else {
    estadoFila = "Cheia";
  }
  // A distancia classifica a fila; nao mede a quantidade real de pessoas.
}

void lerBotao(Botao &botao, const char *mensagem) {
  const unsigned long agora = millis();
  const bool leitura = digitalRead(botao.pino) == LOW;
  if (leitura != botao.ultimaLeitura) {
    botao.ultimaLeitura = leitura;
    botao.mudouEm = agora;
  }
  if (agora - botao.mudouEm >= DEBOUNCE_MS &&
      leitura != botao.pressionado) {
    botao.pressionado = leitura;
    if (leitura) Serial.println(mensagem);
  }
}

void atualizarBotoes() {
  lerBotao(botaoEmergencia, "[ALERTA] EMERGENCIA!");
  lerBotao(botaoAglomeracao, "[ALERTA] AGLOMERACAO!");
  lerBotao(botaoEquipe, "[ALERTA] EQUIPE SOLICITADA!");
  // Alertas manuais permanecem ativos enquanto o botao estiver pressionado.
  if (botaoEmergencia.pressionado && !emergencia) totalEmergencias++;
  if (botaoAglomeracao.pressionado && !aglomeracao) totalAglomeracoes++;
  if (botaoEquipe.pressionado && !equipe) totalEquipes++;
  emergencia = botaoEmergencia.pressionado;
  aglomeracao = botaoAglomeracao.pressionado;
  equipe = botaoEquipe.pressionado;
}

void atualizarClima() {
  const TempAndHumidity leitura = dht.getTempAndHumidity();
  if (isnan(leitura.temperature) || isnan(leitura.humidity)) {
    temperatura = NAN;
    umidade = NAN;
    Serial.print("[CLIMA] Falha no DHT22: ");
    Serial.println(dht.getStatusString());
    return;
  }
  temperatura = leitura.temperature;
  umidade = leitura.humidity;
  Serial.printf("[CLIMA] Temperatura: %.1f C | Umidade: %.1f%%\n",
                temperatura, umidade);
}

void atualizarIndicadores() {
  // 0 = normal, 1 = atencao, 2 = critico.
  // O estado mais grave prevalece e apenas uma cor fica acesa.
  int nivel = 0;
  if (pessoas >= LIMITE_CRITICO || estadoFila == "Cheia" ||
      (!isnan(temperatura) && temperatura >= 30.0f) || emergencia) {
    nivel = 2;
  } else if (pessoas >= LIMITE_ATENCAO || estadoFila == "Moderada" ||
             (!isnan(temperatura) && temperatura >= 25.0f) || aglomeracao) {
    nivel = 1;
  }

  digitalWrite(LED_VERDE, nivel == 0 ? HIGH : LOW);
  digitalWrite(LED_AMARELO, nivel == 1 ? HIGH : LOW);
  digitalWrite(LED_VERMELHO, nivel == 2 ? HIGH : LOW);

  const bool som = nivel == 2 || aglomeracao || equipe;
  const bool emitir = som && (millis() % 1000UL < 200UL);
  // O buzzer do Wokwi e passivo: precisa de uma frequencia audivel.
  static bool emitindo = false;
  if (emitir != emitindo) {
    emitindo = emitir;
    if (emitir) tone(BUZZER, 2000);
    else noTone(BUZZER);
  }
}

void imprimirStatus() {
  Serial.println("\n======= CROWLY =======");
  Serial.printf("Pessoas no local: %d\n", pessoas);
  Serial.printf("Estado da fila: %s\n", estadoFila.c_str());
  if (!isnan(distancia)) Serial.printf("Distancia: %.1f cm\n", distancia);
  else Serial.println("Distancia: sem leitura valida");
  if (!isnan(temperatura) && !isnan(umidade)) {
    Serial.printf("Temperatura: %.1f C\n", temperatura);
    Serial.printf("Umidade: %.1f%%\n", umidade);
  } else {
    Serial.println("Clima: sem leitura valida");
  }
  Serial.printf("Emergencia: %s\n", emergencia ? "ATIVA" : "Inativa");
  Serial.printf("Aglomeracao: %s\n", aglomeracao ? "ATIVA" : "Inativa");
  Serial.printf("Equipe: %s\n", equipe ? "Solicitada" : "Nao solicitada");
  Serial.println("======================\n");
}

void setup() {
  Serial.begin(115200);
  configurarGPIO();
  dht.setup(DHT_PIN, DHTesp::DHT22);
  // O agendador aguarda 2500 ms antes da primeira leitura do DHT22.
  ultimaLeituraDHT = millis();
  Serial.println("\nCROWLY iniciada!");
  Serial.println("Monitoramento local e envio Supabase ativos.");
  // HTTPS pode executar calculos longos. Compartilhar prioridade com IDLE0
  // permite que o escalonador execute o idle e alimente o watchdog.
  // O watchdog continua ativo, sem alterar seu timeout.
  if (xTaskCreatePinnedToCore(redeTask, "crowly-network", 16384, nullptr, tskIDLE_PRIORITY, nullptr, 0) != pdPASS) {
    Serial.println("[REDE] Nao foi possivel iniciar a tarefa de rede.");
  }
}

void loop() {
  const unsigned long agora = millis();
  atualizarContagem();
  atualizarBotoes();

  if (agora - ultimaLeituraUltrassom >= INTERVALO_ULTRASSOM) {
    ultimaLeituraUltrassom = agora;
    atualizarFila();
  }
  if (agora - ultimaLeituraDHT >= INTERVALO_DHT) {
    ultimaLeituraDHT = agora;
    atualizarClima();
  }
  atualizarIndicadores();

  if (agora - ultimoRelatorio >= INTERVALO_RELATORIO) {
    ultimoRelatorio = agora;
    imprimirStatus();
  }
  portENTER_CRITICAL(&snapshotMutex);
  latestSnapshot = {totalEntradas,totalSaidas,totalEmergencias,totalAglomeracoes,totalEquipes,temperatura,umidade,distancia};
  portEXIT_CRITICAL(&snapshotMutex);
  delay(10);
}


void redeTask(void*) {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD, 6);
  configTime(0, 0, "pool.ntp.org", "time.google.com");
  char boot[37];
  uint8_t bytes[16];
  for (int i=0;i<16;i++) bytes[i]=(uint8_t)esp_random();
  bytes[6]=(bytes[6]&15)|64;
  bytes[8]=(bytes[8]&63)|128;
  snprintf(boot,sizeof(boot),"%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
    bytes[0],bytes[1],bytes[2],bytes[3],bytes[4],bytes[5],bytes[6],bytes[7],bytes[8],bytes[9],bytes[10],bytes[11],bytes[12],bytes[13],bytes[14],bytes[15]);
  uint32_t seq=0;
  unsigned long lastAttempt=millis();
  unsigned long lastReconnect=0;
  String pending;
  bool wifiLogged = false;
  bool clockLogged = false;
  unsigned long lastClockLog = 0;
  for (;;) {
    vTaskDelay(pdMS_TO_TICKS(100));
    const unsigned long now=millis();
    if (strlen(DEVICE_TOKEN)!=64) {
      if (now-lastAttempt>=10000) {
        Serial.println("[REDE] Cole a credencial de 64 caracteres no config.h (Perfil > Conectar ESP32).");
        lastAttempt=now;
      }
      continue;
    }
    if (WiFi.status()!=WL_CONNECTED) {
      wifiLogged = false;
      clockLogged = false;
      if (now-lastReconnect>=15000) {
        lastReconnect=now;
        Serial.println("[REDE] Reconectando ao Wi-Fi...");
        WiFi.reconnect();
      }
      continue;
    }
    if (!wifiLogged) {
      Serial.println("[REDE] Wi-Fi conectado.");
      wifiLogged = true;
    }
    // A verificacao TLS precisa de um relogio valido. Sensores continuam ativos.
    if (time(nullptr)<1700000000) {
      if (now-lastClockLog>=15000) {
        lastClockLog=now;
        Serial.println("[REDE] Aguardando sincronizacao NTP para validar HTTPS...");
      }
      continue;
    }
    if (!clockLogged) {
      Serial.println("[REDE] Relogio sincronizado; HTTPS disponivel.");
      clockLogged = true;
    }
    if (now-lastAttempt<10000) continue;
    lastAttempt=now;
    if (pending.isEmpty()) {
      Snapshot s;
      portENTER_CRITICAL(&snapshotMutex);
      s=latestSnapshot;
      portEXIT_CRITICAL(&snapshotMutex);
      JsonDocument document;
      document["device_token"]=DEVICE_TOKEN;
      JsonObject data=document["payload"].to<JsonObject>();
      data["boot_id"]=boot;
      data["seq"]=++seq;
      JsonObject counts=data["counters"].to<JsonObject>();
      counts["entries"]=s.entries;
      counts["exits"]=s.exits;
      counts["emergency"]=s.emergency;
      counts["crowding"]=s.crowding;
      counts["team"]=s.team;
      data["temperature"]=nullptr;
      data["humidity"]=nullptr;
      data["distance_cm"]=nullptr;
      if (!isnan(s.temperature)) data["temperature"]=s.temperature;
      if (!isnan(s.humidity)) data["humidity"]=s.humidity;
      if (!isnan(s.distance) && s.distance>=2 && s.distance<=450) data["distance_cm"]=s.distance;
      serializeJson(document,pending);
    }
    WiFiClientSecure tls;
    tls.setCACert(CROWLY_CA_ROOTS);
    tls.setHandshakeTimeout(15);
    HTTPClient http;
    http.setConnectTimeout(15000);
    http.setTimeout(15000);
    if (!http.begin(tls,String(SUPABASE_URL)+"/rest/v1/rpc/crowly_ingest")) {
      Serial.println("[REDE] Nao foi possivel iniciar HTTPS.");
      continue;
    }
    http.addHeader("Content-Type","application/json");
    http.addHeader("apikey",SUPABASE_ANON_KEY);
    http.addHeader("Authorization",String("Bearer ")+SUPABASE_ANON_KEY);
    Serial.println("[SUPABASE] Iniciando envio HTTPS...");
    const int code=http.POST(pending);
    Serial.printf("[SUPABASE] HTTP %d\n",code);
    if (code==200) {
      JsonDocument response;
      const auto parseError=deserializeJson(response,http.getString());
      if (!parseError) {
        if (response["accepted"]==true) {
          Serial.print("[SUPABASE] Leitura recebida. Pessoas no evento: ");
          Serial.println(response["people"].as<int>());
        } else {
          Serial.print("[SUPABASE] Pacote ignorado: ");
          Serial.println(response["reason"].as<const char*>());
        }
        pending="";
      }
    } else if (code>0) {
      // Nao imprime a credencial nem o corpo do pacote enviado.
      JsonDocument failure;
      if (!deserializeJson(failure,http.getString())) {
        const char* message=failure["message"] | "Erro sem mensagem.";
        Serial.print("[SUPABASE] ");
        Serial.println(message);
      }
      Serial.println("[SUPABASE] Confira a credencial, o SQL complementar e se o evento esta em andamento.");
    } else {
      Serial.println(HTTPClient::errorToString(code));
      Serial.println("[SUPABASE] Falha de transporte. Confira Wi-Fi, NTP e certificados; nao desative a verificacao TLS.");
    }
    http.end();
  }
}