# CROWLY — Especificação visual e funcional

> Referência: `image(4).png`, `image(5).png` e `image(6).png`. Este documento descreve as 18 telas completas visíveis nas capturas. Os rótulos cinza sobre os frames pertencem ao canvas do Figma e não fazem parte do aplicativo.
>
> Fidelidade: estrutura, hierarquia, textos legíveis e cores amostradas estão documentados a partir das imagens. Fontes, medidas originais, assets, curvas dos gráficos e interações não são recuperáveis com exatidão pelas capturas. Valores marcados como **estimativa** são orientações de reconstrução, não propriedades confirmadas do Figma. Não há garantia de equivalência pixel a pixel sem o arquivo original.

## 1. Produto e linguagem visual

Aplicativo móvel de monitoramento de público em eventos, com ocupação de áreas, fluxo de entrada e saída, dispositivos, relatórios e central de alertas. Interface em português, tema escuro roxo, destaque rosa e violeta. Cards compactos, cantos arredondados, ícones lineares e alta densidade de informação.

### 1.1 Referências e inventário

| ID | Tela / estado | Imagem | Posição da esquerda para a direita |
| --- | --- | --- | --- |
| AUTH-01 | Cadastro | 4 | 1 |
| AUTH-02 | Login | 4 | 2 |
| HOME-01 | Home | 4 | 3 |
| MAP-01 | Mapa — dashboard | 4 | 4 |
| MAP-02 | Mapa — área selecionada | 4 | 5 |
| EVT-01 | Eventos | 5 | 1 |
| EVT-02 | Evento passado — detalhes | 5 | 2 |
| EVT-03 | Evento futuro — detalhes | 5 | 3, frame completo inferior |
| CAL-01 | Calendário — página principal | 5 | 4 |
| CAL-02 | Calendário — evento específico | 5 | 5 |
| CAL-03 | Calendário — sem eventos | 5 | 6 |
| CAL-04 | Calendário — carregando | 5 | 7 |
| EVT-04 | Busca sem resultados | 5 | 8 |
| DEV-01 | Dispositivos | 6 | 1 |
| DEV-02 | Dispositivos — sem evento | 6 | 2 |
| DEV-03 | Dispositivo offline | 6 | 3 |
| REP-01 | Relatórios | 6 | 4 |
| REP-02 | Relatórios — sem evento | 6 | 5 |
| ALT-01 | Central de Alertas | 6 | 6 |

O fragmento de frame no alto da imagem 5 não contém conteúdo suficiente para especificar uma tela adicional.

## 2. Fundação visual

### 2.1 Paleta

As cinco primeiras cores abaixo foram obtidas de pixels recorrentes das imagens. Antialiasing, opacidade e composição podem produzir outras tonalidades.

| Token | Valor | Aplicação |
| --- | --- | --- |
| `color.background` | `#1A0033` | Fundo dominante dos frames |
| `color.surface` | `#230A3B` | Superfície recorrente dos cards |
| `color.surfaceRaised` | `#2C1443` | Campos e superfícies internas |
| `color.navigation` | `#402B54` | Barra inferior |
| `color.primary` | `#FF4DB8` | CTA principal, chips selecionados e barras rosa |
| `color.accent` | Violeta vivo, aproximadamente `#9747FF` | Seleção da navegação, gráficos e progresso |
| `color.textPrimary` | Branco ou quase branco | Títulos e valores |
| `color.textSecondary` | Lavanda/cinza claro | Legendas e metadados |
| `color.success` | Verde vivo | Online, entradas, indicadores seguros |
| `color.warning` | Amarelo | Atenção, estados médios e manutenção |
| `color.danger` | Vermelho/coral | Área crítica, saídas e emergência |
| `color.info` | Azul | Ícone do alerta de bateria |

As cores sem hexadecimal confirmado devem ser ajustadas visualmente à referência, sem assumir que são tokens originais.

### 2.2 Tipografia e marca

- Wordmark `CROWLY` em caixa alta, condensado e estreito; branco com detalhe multicolorido central. Usar asset original para conservar a identidade.
- Símbolo de marca: arco aberto em forma de C, três pessoas e trilhas de circuito à direita. Gradiente rosa/violeta, com terminais rosa, amarelo e violeta.
- Textos da interface em sans-serif. Família exata não identificável.
- Hierarquia: títulos de seção em negrito; valores de indicadores em negrito e maiores que suas legendas; metadados pequenos e suaves; chips muito compactos.
- **Estimativa para um frame lógico com largura de 390 px:** corpo 12–14 px, títulos 16–20 px, valores 20–26 px, legendas 10–12 px. Validar pelo enquadramento da referência, não tratar como medidas do Figma.

### 2.3 Geometria e espaçamento

- Os frames aparecem com aproximadamente 194 px de largura nas capturas; isso representa a escala da exportação, não a largura nativa do aplicativo.
- **Estimativa em largura lógica de 390 px:** margem lateral de 20 px; espaçamento de 12–20 px entre blocos; padding interno de 12–16 px; raio de cards de 12–20 px; controles de 40–48 px de altura.
- Fundo sólido e contínuo. Cards em roxo ligeiramente mais claro, com borda discreta e, em alguns casos, brilho ou sombra suave.
- Cards de indicadores agrupados em duas ou três colunas conforme a tela; conteúdo alinhado à esquerda.
- Manter as diferenças de altura entre telas. A Home, os detalhes de evento passado e Relatórios têm conteúdo mais extenso.
- Não interpretar o fundo cinza-claro do canvas como parte do produto.

## 3. Componentes compartilhados

### 3.1 Cabeçalho autenticado

Wordmark pequeno à esquerda. À direita, dois botões circulares contornados: sino e perfil. Ícones claros sobre preenchimento roxo translúcido. Alinhamento horizontal com o conteúdo principal.

### 3.2 Navegação inferior

Barra flutuante arredondada, com margem lateral e inferior. Ícone sobre legenda. Item ativo com disco violeta luminoso e texto branco; demais itens em lavanda acinzentado.

| Variante | Itens, na ordem | Ativo |
| --- | --- | --- |
| Padrão | Home, Eventos, Dispositivos, Relatórios, Alertas | Conforme a seção |
| Mapas | Home, Eventos, Dispositivos, Alertas | Home |

Preservar a variante de quatro itens nos mapas: a referência não exibe Relatórios nessas duas telas. A fixação durante rolagem não pode ser confirmada; recomenda-se manter a barra acessível e reservar espaço no conteúdo.

### 3.3 Botões e campos

- Primário: rosa preenchido, texto branco em negrito, cantos arredondados.
- Secundário: fundo escuro, contorno violeta ou rosa e texto claro.
- Terciário: link textual rosa.
- Campo: fundo roxo elevado, contorno suave, ícone inicial e placeholder claro; senha com controle de visibilidade à direita.
- Busca: campo horizontal com lupa; no estado preenchido, botão de limpar à direita.
- Filtros: chips arredondados, selecionado rosa ou violeta conforme a tela, inativos escuros com contorno discreto.

### 3.4 Indicadores, progresso e alertas

- Indicador: legenda pequena, número em destaque e ícone opcional em quadrado arredondado.
- Progresso: trilho roxo escuro e preenchimento rosa ou violeta; percentual e badge à direita.
- Alerta: ícone em bloco colorido à esquerda, título e descrição empilhados, badge à direita. Central de Alertas acrescenta chevron.
- Não unificar severidade e andamento: `Alta`, `Média` e `Baixa` indicam severidade; `Em análise` e `Resolvido` indicam tratamento.
- Estado vazio: símbolo central em círculos concêntricos ou marca, título branco, descrição e ação.

## 4. Autenticação

### AUTH-01 — Cadastro

Composição centralizada, sem cabeçalho de navegação ou barra inferior.

1. Símbolo grande da marca.
2. Wordmark `CROWLY`.
3. Frase `Feito para os seus melhores dias`.
4. Título `Crie uma conta!`.
5. Subtítulo `Preencha os dados pra começar`.
6. Card de formulário com campos empilhados: `Nome completo`, `E-mail`, `Senha`, `Confirmar senha`.
7. Botão primário `Entrar` — preservar esse rótulo, mesmo na tela de cadastro.
8. Texto `Já tem uma conta?` e link `Logar`.
9. Texto de aceite com link `Termos de Uso`.

Campos com ícones de pessoa, e-mail e cadeado. Os dois campos de senha têm olho riscado. Card largo, com padding e brilho roxo discreto; botão ocupa toda a largura interna.

### AUTH-02 — Login

Mesma composição de marca e frase da tela de cadastro.

- Título `Bem-vindo de volta!`.
- Subtítulo `Entre com suas credenciais`.
- Card com `E-mail` e `Senha`.
- Link `Esqueceu a senha?` alinhado à direita abaixo da senha.
- Botão primário `Entrar`.
- Texto `Não tem uma conta?` com link `Cadastre-se`.
- Rodapé de aceite com `Termos de Uso`.

O card é mais baixo que o de cadastro. Erros de validação, recuperação e confirmação de cadastro não estão representados.

## 5. Home e mapas

### HOME-01 — Home

Ordem vertical obrigatória:

1. Cabeçalho.
2. Card de evento com fotografia de fundo escurecida e borda violeta: badge `AO VIVO`, `Rock in Rio 2026`, `Parque Olímpico - Palco Sunset`, indicadores `Pessoas 12.4k` e `Ocupação 68%`.
3. `Visão Geral`: três cards — `Capacidade Máxima 18.000`, `Ocupação Atual 68%` com progresso, `Público Presente 12.4k`.
4. `Horários de Maior Movimento`: gráfico de barras com sete posições, de 12h a 22h; duas barras de pico rosa no trecho final e demais violetas. Alturas exatas não disponíveis.
5. `Áreas monitoradas`: quatro barras, conforme tabela.
6. Link central `Ver todas as áreas`.
7. `Alertas ativos` com contador `3 ativos`.
8. Três cards de alerta.
9. Navegação padrão com Home ativo.

| Área | Ocupação | Badge | Barra |
| --- | --- | --- | --- |
| Palco Sunset | 93% | Alta | Rosa |
| Pista | 45% | Normal | Violeta |
| VIP Lounge | 63% | Normal | Violeta |
| Bar Central | 74% | Alta | Rosa |

| Alerta | Descrição | Badge |
| --- | --- | --- |
| Fila do bar acima do limite | 45 pessoas aguardando | Média |
| Alerta de suporte - área B | Necessidade de equipe imediata | Alta |
| Temperatura elevada - VIP (L) | 29°C - atenção recomendada | Baixa |

A abreviação final do título de temperatura tem baixa resolução; confirmar no Figma antes de fixar o texto final.

### MAP-01 — Mapa / dashboard

- Cabeçalho compartilhado.
- Card de evento: chips `EM ANDAMENTO` e `AO VIVO`, horário da última atualização à direita, título `Festival Conecta 2026`, período de agosto de 2026 e local `Parque Olímpico - Rio de Janeiro`.
- Ações horizontais `Atualizar`, `Alertas (3)` e `Encerrar`; a última usa cor de perigo.
- Card `Mapa de Ocupação Real-Time`, com controles `+` e `−` no canto superior direito.
- Mapa esquemático de blocos retangulares, sem geografia real ou mapa de ruas.

| Posição | Área | Valor / estado |
| --- | --- | --- |
| Superior esquerda, bloco largo | Palco Principal | 91%, vermelho |
| Superior direita | Área VIP | 83%, violeta |
| Inferior esquerda, bloco alto | Entrada | Verde |
| Centro, acima | Alimentação | 78%, amarelo |
| Centro, abaixo | Bar | 75%, amarelo |
| Inferior direita, acima | Banheiros | Verde |
| Inferior direita, abaixo | Saída | Verde |

Legenda sob o mapa: seguro em verde, atenção em amarelo e crítico em vermelho. Os intervalos pequenos parecem indicar `<70%`, `70–85%` e `>85%`; confirmar os limites no original. A Área VIP aparece violeta mesmo dentro da faixa de atenção: preservar essa diferença visual.

Grade de indicadores em três colunas e duas linhas:

| Público total | Entradas | Saídas |
| --- | --- | --- |
| 12.847 | 14.230 | 1.383 |

| Capacidade | Em atenção | Alertas |
| --- | --- | --- |
| 68% | 2 áreas | 3 ativos |

`Alertas recentes`, contador `3 ativos`, dois itens visíveis: `Palco Principal atingiu 91%` com badge Alta; `Fluxo intenso na Praça de Alimentação` com badge Médio. Barra inferior na variante de quatro itens.

### MAP-02 — Área selecionada

1. Cabeçalho.
2. Card `Mapa — Área Selecionada` com o mesmo arranjo de blocos.
3. Palco Principal destacado por borda rosa brilhante; demais blocos escurecidos.
4. Card de detalhe `Palco Principal`, horário de atualização e badge `Crítico`.
5. Anel de ocupação vermelho/coral com `91%` no centro e legenda `Ocupação`.
6. Ao lado: `Pessoas no local 6.643`, `Capacidade Max 7.300`, `Sensores ativos 8/8` em verde.
7. Três minicards: `Entradas (últ. hora) +1.230`, `Saídas (últ. hora) -456`, `Tendência ↑ Crescente`.
8. Ações `Ver histórico` contornada e `Acionar equipe` rosa.
9. Navegação de quatro itens com Home ativo.

## 6. Eventos

### EVT-01 — Eventos

Cabeçalho, busca `Buscar eventos...`, chips `Futuros` ativo em rosa, `Passados` e `Calendário` inativos. A captura exibe seções Futuros e Passados simultaneamente; preservar o conteúdo visível, sem presumir uma filtragem que o ocultaria.

| Seção | Evento | Metadados legíveis |
| --- | --- | --- |
| Futuros | Rock in rio 2026 | 31/11/2026 · 18:00; Parque olímpico; 730k pessoas |
| Futuros | Lollapalooza 2026 | 20–22/03/2026 · 12:00; Autódromo de Interlagos; 100k pessoas |
| Passados | The Town Club | 4–6 e 11–12/09/2026; Autódromo de Interlagos |
| Passados | Taubaté Expo Agro | 20–23/11/2026; Arena Nacional do Vale do Paraíba |

Cada card tem thumbnail à esquerda e dados à direita, com ícones de calendário, localização e pessoas. Os dois passados têm botão rosa `Ver dados`. Algumas datas estão pequenas e exigem confirmação; `31/11` é a leitura aparente, embora não seja uma data válida. Não corrigir silenciosamente a referência. Navegação padrão com Eventos ativo.

### EVT-02 — Evento passado / detalhes

- Cabeçalho.
- Três indicadores: `Público Total 98.2k`, `Pico Ocupação 87%`, `Média Ocupação 62%`.
- Card `Fluxo de Entradas / Saídas`: `Total Entradas 98.2k`, `Total Saídas 96.8k` e metadados pequenos de pico.
- Card `Ocupação ao longo do tempo`: linha violeta com preenchimento degradê sobre fundo roxo; eixos e horários pequenos.
- Card `Entradas e Saídas por Hora`: barras pareadas violetas e rosas.
- Faixa ambiental: `Temp. Média 28°C` e `Umidade 65%`.
- `Alertas do Evento`: quatro contadores — Emergência 2, Alta 4, Média 4, Baixa 2.
- Cards `Superlotação - Palco Sunset` / Emergência; `Fila acima do limite - Bar 2` / Alta; `Alerta de suporte - Área B` / Média.
- Ações inferiores `Relatório PDF` preenchida e `Partilhar` contornada.
- Grande intervalo livre antes da navegação, conforme o frame alto; Eventos ativo.

Os pontos dos gráficos não têm valores numéricos recuperáveis. Reproduzir o aspecto visual sem atribuir dados inventados.

### EVT-03 — Evento futuro / detalhes

- Cabeçalho.
- Banner com fundo fotográfico escuro, badge violeta `EVENTO AGENDADO`, título `Parque Olímpico - Sunset` e subtítulo de estimativa de público.
- Card informativo: `31/11/2026 - 18:00 - 06:00`, `Parque Olímpico - Rio de Janeiro`, `Capacidade Máxima: 730k pessoas` — data e escala são as leituras aparentes da captura, pendentes de confirmação.
- `Dispositivos & Sensores`: quatro minicards — Contadores 12, Filas 8, Alertas 6, Ambiental 22.
- Card `PREPARAÇÃO DO EVENTO`, percentual verde `87,5% OK`, barra de progresso e resumo de dispositivos online, offline e em manutenção.
- Lista de pendências com três linhas: sensor de fila, contador da entrada VIP e módulo de áudio; badges `Offline`, `Em Manutenção`, `Offline`.
- Botão rosa largo `Iniciar Monitoramento`.
- Navegação padrão com Eventos ativo.

## 7. Calendário e busca

### CAL-01 — Calendário principal

- Cabeçalho.
- Título `Calendário de eventos` e subtítulo `Visualize e gerencie todos os eventos da Eventos Prime`.
- Botão compacto rosa `Novo evento`.
- Linha de navegação do mês: seta anterior, `Agosto 2026`, botão `Hoje`, seta seguinte.
- Seletor `Mês` ativo em violeta, `Semana`, `Lista`.
- Busca `Buscar por nome ou local`.
- Filtros de situação: `Todos` ativo em rosa, `Agendados`, `Em andamento`, `Encerrados`, `Cancelados`; manter em uma linha como na referência.
- Grade mensal de sete colunas: Dom, Seg, Ter, Qua, Qui, Sex, Sáb; células escuras, números pequenos, marcadores compactos violetas e verdes nos dias com evento.
- Navegação padrão com Eventos ativo.

### CAL-02 — Evento selecionado

Cabeçalho seguido diretamente pelo card do calendário. Um dia recebe preenchimento violeta destacado, com marcador de evento verde; os demais dias mantêm superfícies discretas.

Abaixo, card de resumo com borda violeta:

- `Festival Conecta 2026` e badge rosa `AO VIVO`.
- `05–07 de Agosto, 2026 • 18:00 - 02:00`.
- `Parque Olímpico - Rio de Janeiro`.
- `Capacidade: 730k pessoas` — leitura aparente da escala na imagem.
- `Ocupação atual 68%`, progresso rosa.
- Botões `Ver detalhes` contornado e `Acessar monitoramento` preenchido.
- Navegação padrão com Eventos ativo.

### CAL-03 — Sem eventos

- Cabeçalho.
- `Novembro 2026` e setas anterior/próximo.
- Card de calendário apenas com cabeçalhos dos dias da semana no estado mostrado.
- Card vazio com símbolo grande CROWLY.
- Título `Nenhum evento encontrado`.
- Descrição `Não há eventos cadastrados para este período.`.
- CTA rosa `Criar primeiro evento`.
- Navegação padrão com Eventos ativo.

### CAL-04 — Carregando

Cabeçalho, spinner circular violeta centralizado e legenda `Carregando eventos...`. Abaixo, dois skeletons: um bloco grande simulando calendário, com linhas e células; um bloco baixo com linhas horizontais simulando resumo. Sem brilho de animação confirmável na imagem estática. Navegação padrão com Eventos ativo.

### EVT-04 — Busca sem resultados

- Cabeçalho e título condensado `EVENTOS`.
- Busca preenchida com `festival xyz`, lupa e controle de limpar.
- Chips `Futuros` ativo e `Passados` inativo.
- Ícone de busca sem resultado dentro de círculos concêntricos.
- `Nenhum resultado encontrado`.
- `Tente buscar com outros termos ou verifique os filtros aplicados.`.
- Botão contornado largo `Limpar busca`.
- Navegação padrão com Eventos ativo.

## 8. Dispositivos

### DEV-01 — Lista

Cabeçalho e três cards de resumo: `Total 12`, `Ativos 10`, `Alertas 2`.

| Grupo | Item | Valor / badge |
| --- | --- | --- |
| Contadores de pessoas | Entrada Principal | 1.2k |
| Contadores de pessoas | Palco Sunset | 180 |
| Contadores de pessoas | VIP Lounge | 45 |
| Contadores de pessoas | Bar Central | 64 |
| Sensores de fila | Bar 2 | 45 |
| Sensores de fila | Bilheteria | 12 |
| Sensores de fila | Banheiro | 8 |
| Botões de alerta | Área B | Suporte |
| Botões de alerta | Palco | Emergência |
| Monitoramento ambiental | Área VIP | 29°C |
| Monitoramento ambiental | Palco | 26°C |

Títulos de grupo com ícone em pequeno quadrado colorido. Cada dispositivo ocupa uma linha em card arredondado: ponto de estado à esquerda, nome, valor à direita. Pontos verdes para contadores, filas e ambiente; amarelo para Área B e vermelho para Palco. Temperaturas com ícone de termômetro e texto verde. Navegação com Dispositivos ativo.

A lista e os contadores de resumo não precisam ser reconciliados: reproduzem exemplos visuais da captura.

### DEV-02 — Sem evento

Cabeçalho, ícone de pulso em círculos concêntricos violetas com pequeno ponto rosa, título `Nenhum evento ativo`, descrição `Os dispositivos aparecerão aqui quando houver um evento em andamento.`, botão roxo largo `Ver eventos futuros`. Espaço livre amplo abaixo. Navegação com Dispositivos ativo.

### DEV-03 — Dispositivo offline

- Cabeçalho; título condensado `DISPOSITIVO`.
- Card: categoria rosa `CONTADOR DE PESSOAS`, badge `Portão A`, nome `Contador - Entrada Principal`.
- Card de estado com contorno rosa: chip `OFFLINE`, texto `Este dispositivo está offline`, descrição `Última comunicação: há 15 minutos`.
- Card de propriedades: `Bateria 45%`, `Intensidade do Sinal Sem sinal`, `Última Leitura 1.247 pessoas`.
- Botão rosa largo `Reiniciar remotamente`.
- Botão contornado largo `Reportar problema`.
- Navegação com Dispositivos ativo.

## 9. Relatórios

### REP-01 — Relatórios

1. Cabeçalho.
2. `Resumo` com dois cards empilhados: `Ingressos 19,4k`, variação positiva violeta; `Ocupação 68%`, variação amarela. Os percentuais pequenos de variação devem ser confirmados no arquivo original.
3. `Histórico` acompanhado de ícone de gráfico; card `Últimos 6 eventos realizados`, `Média de ocupação: 72%`.
4. `Fluxo por Área`, conforme tabela.
5. `Histórico de Movimentação`: duas linhas, rosa para Entradas e violeta para Saídas, pontos pequenos, grid horizontal discreto e horários de 10h a 22h.
6. `Capacidade e Ocupação`: dois cards lado a lado — `Capacidade Máxima 18.000`, `Ocupação Média 72%` com progresso.
7. Navegação com Relatórios ativo.

| Área | Percentual | Badge |
| --- | --- | --- |
| Palco Sunset | 65% | Alta |
| Pista | 45% | Normal |
| VIP Lounge | 53% | Normal |
| Bar Central | 55% | Alta |
| Alimentação | 38% | Normal |

Os badges Alta mesmo com valores menores aparecem assim na referência; não aplicar automaticamente os limites do mapa a este relatório. O gráfico apresenta um traço que alcança a borda direita; não inventar séries ou uma escala vertical inexistente.

### REP-02 — Sem evento

Cabeçalho, ícone rosa de gráfico de barras em círculos concêntricos, título `Nenhum relatório disponível`, descrição `Os relatórios serão gerados após a realização de um evento.`, botão roxo/rosa escuro `Ver eventos passados`. Navegação com Relatórios ativo.

## 10. ALT-01 — Central de Alertas

Cabeçalho; filtros em linha `Todos` selecionado em rosa, `Emergência`, `Alta`, `Média`, e botão quadrado de ajustes à direita. A borda da linha sugere conteúdo adicional; não adicionar filtros invisíveis como se estivessem confirmados.

Quatro contadores: `Emergência 1`, `Alta 2`, `Média 3`, `Baixa 1`.

| Ordem | Título | Descrição legível | Estado à direita |
| --- | --- | --- | --- |
| 1 | Superlotação - Palco Sunset | 92% Ocupação • 1 min atrás | Alta |
| 2 | Fila acima do limite - Bar 2 | 45 pessoas • 12 min atrás | Em análise |
| 3 | Alerta de suporte - Área B | Equipe Acionada • 20 min atrás | Resolvido |
| 4 | Temperatura elevada - VIP Lounge | 29°C • 35 min atrás | Alta |
| 5 | Sensor offline - Entrada 3 | Sem sinal • 1h atrás | Em análise |
| 6 | Bateria fraca - Sensor 12 | Bateria 10% • 2h atrás | Resolvido |

Cards com ícones de triângulo em blocos coloridos: vermelho no primeiro, rosa nos dois seguintes, amarelo nos dois seguintes e azul no último. Chevrons claros à direita. Badges Alta rosa; Em análise amarelo contornado; Resolvido verde contornado. Navegação com Alertas ativo.

Os sete alertas dos contadores e os seis cards visíveis não demonstram erro: pode haver conteúdo fora do recorte. Não fabricar um sétimo card.

## 11. Interações sugeridas para implementação

> Esta seção interpreta os controles visíveis. As capturas não comprovam destinos, regras, APIs ou comportamento dos protótipos.

| Origem | Controle | Comportamento sugerido |
| --- | --- | --- |
| Cadastro / Login | Logar / Cadastre-se | Alternar entre as telas de autenticação |
| Senha | Olho riscado | Alternar visibilidade do campo |
| Cabeçalho | Sino | Abrir a Central de Alertas |
| Navegação inferior | Item | Abrir sua seção e atualizar seleção |
| Home | Ver todas as áreas | Abrir o mapa/dashboard |
| Mapa | Bloco da área | Abrir o estado de área selecionada |
| Eventos | Calendário | Abrir CAL-01 |
| Evento passado | Ver dados | Abrir EVT-02 |
| Calendário | Dia com evento | Mostrar CAL-02 |
| Calendário | Setas / Hoje | Alterar período ou retornar ao atual |
| CAL-02 | Acessar monitoramento | Abrir MAP-01 |
| Estado vazio de dispositivos | Ver eventos futuros | Abrir Eventos |
| Estado vazio de relatórios | Ver eventos passados | Abrir Eventos / passados |
| Busca sem resultado | Limpar busca | Limpar o termo e atualizar a listagem |
| Dispositivo | Item offline | Abrir DEV-03 |
| Alerta | Card / chevron | Abrir detalhe; tela de destino não fornecida |

Reinício remoto, encerramento do evento, acionamento de equipe, criação de evento, perfil, PDF e compartilhamento têm controles visíveis, mas seus fluxos posteriores não estão desenhados. Definir esses fluxos separadamente; não inventar telas como parte da reprodução.

## 12. Regras de fidelidade e aceite

- [ ] Reproduzir as 18 telas na ordem e hierarquia documentadas.
- [ ] Usar fundo `#1A0033` e CTA principal `#FF4DB8`.
- [ ] Preservar marca, símbolo, thumbnails e fotografias com assets originais quando disponíveis.
- [ ] Manter títulos, números, nomes de áreas e badges próprios de cada tela; não normalizar dados de telas diferentes.
- [ ] Conservar as variantes de quatro e cinco itens da navegação inferior.
- [ ] Reproduzir os estados vazio, carregando, sem resultado, offline e área selecionada.
- [ ] Manter o mapa como diagrama de blocos e o destaque rosa na área selecionada.
- [ ] Preservar número de colunas dos indicadores e ordem de seções.
- [ ] Conferir fontes, pesos, raios, opacidades e medidas no Figma antes de alegar reprodução exata.
- [ ] Comparar capturas lado a lado na mesma escala e proporção dos frames.
- [ ] Garantir que a barra inferior não cubra o conteúdo em telas roláveis.
- [ ] Não introduzir elementos do canvas, como títulos externos cinza, na interface.

## 13. Informações pendentes para equivalência exata

1. Dimensões nativas dos frames e comportamento de Auto Layout/constraints.
2. Famílias e arquivos de fontes, pesos, entrelinhas e espaçamento entre letras.
3. SVGs da marca, biblioteca de ícones e imagens de eventos.
4. Tokens completos de cores, gradientes, transparências, bordas e sombras.
5. Textos pequenos e datas que ficaram reduzidos nas capturas, especialmente novembro e capacidades com sufixo `k`.
6. Dados e coordenadas exatas dos gráficos, detalhes do calendário e limiares de ocupação.
7. Destinos e transições do protótipo, validação de formulários e fluxos não mostrados.

Até esses itens serem confirmados, este documento é uma especificação fiel ao conteúdo visual legível das capturas, com estimativas explicitadas para a reconstrução.
