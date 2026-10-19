# CROWLY · Flutter + Supabase

Aplicativo móvel em português baseado na spec e nas três capturas fornecidas. Tema roxo/rosa, autenticação, eventos, calendário, mapa por áreas, dispositivos, alertas, relatórios e exportação PDF.

## Executar a demonstração

Pré-requisitos: Flutter stable 3.47.7 / Dart 3.13.5 (versões validadas; o lock exige Flutter >= 3.44 e Dart >= 3.12), SDK Android ou Chrome para web. iOS exige macOS e Xcode. Para os scripts de configuração de plataformas, instale também Python 3.

Se as pastas `android`, `ios` e `web` já estiverem no pacote, basta:

```bash
flutter pub get
flutter run --dart-define=DEMO_MODE=true
```

Se precisar gerar ou regenerar as plataformas:

```bash
# Linux/macOS
bash tool/bootstrap.sh

# Windows PowerShell
powershell -ExecutionPolicy Bypass -File tool/bootstrap.ps1
```

Para web:

```bash
flutter run -d chrome --dart-define=DEMO_MODE=true
```

Também é possível usar **Explorar demonstração** na tela de login. A demonstração roda em memória, está identificada como DEMO e reinicia ao sair. Ela não se conecta ao Supabase nem simula a execução física de comandos.

## Conectar ao seu Supabase

1. Crie um projeto Supabase.
2. Execute `supabase/migrations/202610160001_crowly.sql` no SQL Editor de um projeto novo. A migração cria as tabelas, RLS, RPCs e publicação Realtime em uma transação. Não é um script de upgrade para tabelas preexistentes com os mesmos nomes.
3. Ative autenticação por e-mail/senha em Authentication → Providers. Configure o envio de e-mails e mantenha a confirmação de e-mail conforme sua política.
4. Adicione `io.crowly.app://login-callback/` em Authentication → URL Configuration → Redirect URLs. Os arquivos de plataforma e o script incluem esse esquema no Android/iOS. Para confirmação de cadastro via web, configure o Site URL e os redirects para o endereço web publicado.
5. Copie `config.example.json` para `config.local.json`. Substitua `SUPABASE_URL` e `SUPABASE_ANON_KEY` pela URL do projeto e pela chave **publishable** ou **anon**. Nunca use `service_role` no aplicativo.
6. Execute:

```bash
flutter run --dart-define-from-file=config.local.json
```

7. Cadastre uma conta e confirme seu e-mail. A conta começa vazia. Crie eventos pelo botão `+` ou, no perfil, escolha **Adicionar eventos de exemplo** para popular apenas a conta atual.

A chave pública é embutida no aplicativo por design; o isolamento dos dados depende da autenticação e das políticas RLS. Não compartilhe tokens de sessão ou chaves privilegiadas. Não inclua `config.local.json` no controle de versão.

### Recuperação de senha

Informe o e-mail na tela de login e use **Esqueceu a senha?**. O link abre `io.crowly.app://login-callback/` no app instalado e exibe o formulário de nova senha. Para uma implantação exclusivamente web, ajuste o `redirectTo` em `lib/ui/auth.dart` para o domínio HTTPS real e autorize esse endereço no painel Supabase. O URL customizado padrão foi escolhido para Android/iOS.

## Funcionalidades incluídas

- Cadastro, login, logout, sessão persistente, recuperação e atualização de senha.
- Modo demonstração separado dos dados reais.
- Home com ocupação, áreas, indicadores e alertas.
- Mapa esquemático com seleção de área, zoom e solicitação de equipe.
- Listagem, busca, criação e detalhes de eventos; início e encerramento de monitoramento.
- Calendário mensal, semanal e em lista, navegação de período, seleção de dia, busca e filtros de estado.
- Lista de dispositivos por categoria; status offline; fila de reinício remoto e relato de problema.
- Central de alertas com filtros de severidade e tratamento; ações Analisar e Marcar resolvido.
- Relatórios por evento, gráficos a partir das leituras e PDF para impressão/compartilhamento.
- Estados sem evento, sem relatório, sem resultado, carregando e erro com nova tentativa.
- Atualização via Supabase Realtime; pull-to-refresh como atualização manual.

## Estrutura

```text
lib/
  main.dart                 Inicialização, sessão e modo demo
  core/models.dart          Conversão de dados e formatação
  core/theme.dart           Paleta e tema
  data/demo.dart            Fixtures locais
  data/store.dart           Acesso Supabase, Realtime e operações
  ui/auth.dart              Autenticação e recuperação
  ui/shell.dart             Cabeçalho, navegação e carregamento
  ui/widgets.dart           Componentes e gráficos vetoriais
  ui/dashboard.dart         Home, mapa e seleção de área
  ui/events.dart            Eventos, criação e calendário
  ui/devices.dart           Dispositivos e comandos
  ui/alerts.dart            Alertas e tratamento
  ui/reports.dart           Relatórios e PDF
supabase/migrations/        Banco, RLS, relatórios e exemplos
supabase/rls_smoke.sql       Verificação de isolamento em ambiente local
SPEC.md                     Spec visual de referência
VALIDATION.md               Resultado de validação deste pacote
```

## Banco e autorização

| Tabela | Conteúdo | Acesso do usuário autenticado |
| --- | --- | --- |
| events | Agenda, capacidade e totais | CRUD dos próprios eventos |
| areas | Área, posição, capacidade e pessoas | CRUD nos próprios eventos |
| devices | Tipo, status, bateria e última leitura | CRUD nos próprios eventos |
| alerts | Severidade e tratamento | CRUD nos próprios eventos |
| samples | Séries de entradas, saídas e ocupação | CRUD nos próprios eventos |
| reports | Snapshot agregado do encerramento | Somente leitura |
| commands | Solicitações operacionais | Leitura e inserção de comandos queued |

Todas as tabelas têm RLS. As chaves estrangeiras compostas validam que áreas, dispositivos, alertas e comandos pertençam ao mesmo proprietário/evento. `anon` não recebe acesso. O trigger de encerramento gera um único snapshot agregado em `reports`; as tabelas de áreas e leituras permanecem consultáveis, sem congelamento individual de cada linha. Esta versão usa conta individual; colaboração por equipe/organização exige uma tabela de membros e políticas adicionais.

As datas de demonstração são válidas e relativas ao dia de execução. As leituras e curvas são exemplos, pois as capturas não fornecem dados numéricos completos. A data aparente `31/11` da spec não foi usada no banco por ser inválida.

## Sensores e execução de comandos

O app é o painel de monitoramento. Ele **não inclui firmware, gateway IoT ou serviço de despacho físico**.

Um agente de backend confiável deve:

1. Receber e validar leituras dos sensores.
2. Atualizar `devices` (incluindo `last_seen`), `areas` e os totais de `events`.
3. Inserir `samples` com contagens do intervalo e a ocupação percentual. A consulta atual usa o limite de linhas configurado no PostgREST (normalmente 1.000 por tabela); mantenha retenção/agregação e adicione paginação para grandes eventos. As curvas são ordenadas por horário no cliente.
4. Inserir `alerts` conforme os limiares do evento.
5. Consumir `commands` em `queued`, executar o comando real e atualizar para `processing`, `completed` ou `failed` com `completed_at`.

O agente usa credenciais privilegiadas SOMENTE no servidor e informa explicitamente `owner_id` e `event_id` em cada inserção. A fila não é um serviço de execução hospedado neste pacote. Para múltiplos workers, implemente claim transacional de comandos (`FOR UPDATE SKIP LOCKED`), idempotência e confirmação do dispositivo. O aplicativo deixa o estado como **Na fila** até receber o retorno; não afirma que um aparelho reiniciou.

O histórico por área não foi inventado: o botão explica a necessidade de leituras por área. As séries atuais são por evento. O serviço de ingestão e a integração com hardware dependem do protocolo/equipamento escolhido.

## Fidelidade visual

A composição segue as 18 telas/estados da spec, com cores amostradas `#1A0033`, `#230A3B`, `#2C1443`, `#402B54` e `#FF4DB8`. A largura máxima de conteúdo é 520 px para preservar a composição móvel em telas maiores; conteúdo longo tem rolagem e a barra inferior fica fora da área rolável.

Fontes e assets originais não foram fornecidos. A marca foi aproximada em desenho vetorial e Roboto Condensed; a interface e os PDFs usam fontes Roboto incluídas, com suas licenças Apache, sem download de fonte em execução; os cards usam gradiente/ícone quando `image_url` está vazio. Para identidade exata, substitua `Brand`/`BrandSymbol` e forneça as fotografias e fontes licenciadas do Figma. Não há alegação de equivalência pixel a pixel.

Alguns dados foram unificados para manter a aplicação consistente: Home e mapa exibem o mesmo evento; totais derivam do backend, não de valores divergentes entre screenshots. Severidade e tratamento de alerta são campos independentes. A navegação dos mapas tem quatro itens, conforme a referência.

## Verificar e compilar

```bash
dart format lib test
flutter analyze
flutter test
flutter build web --no-web-resources-cdn --dart-define=DEMO_MODE=true
flutter build apk --dart-define-from-file=config.local.json
```

Para testes de RLS, use um Supabase local com a migração aplicada:

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/rls_smoke.sql
```

O teste de banco cria usuários temporários dentro de uma transação e termina com rollback. Não execute testes em um projeto que contenha dados importantes.

Antes de distribuir: substitua os termos provisórios por termos reais, configure marca/ícones, assinatura Android/iOS, e-mail transacional, URL de recuperação para seu destino e o agente de sensores. O pacote entregue é código-fonte, não APK assinado.

## Referências técnicas

- Supabase Flutter: https://supabase.com/docs/guides/getting-started/quickstarts/flutter
- Inicialização: https://supabase.com/docs/reference/dart/initializing
- Realtime: https://supabase.com/docs/reference/dart/stream
- RLS: https://supabase.com/docs/guides/database/postgres/row-level-security
