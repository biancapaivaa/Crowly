# Validação — CROWLY

Ambiente: Flutter 3.47.7 stable, Dart 3.13.5, Linux. Verificação feita em 16/10/2026.

| Verificação | Resultado |
| --- | --- |
| `dart format lib test` | Código formatado |
| `flutter analyze --no-pub` | Sem apontamentos |
| `flutter test --no-pub --reporter expanded` | 8 testes aprovados |
| Build Web de demonstração | Compilação JavaScript aprovada; dry run WebAssembly aprovado |
| Migração SQL executada em PostgreSQL embarcado (PGlite) | Aprovada |
| Testes de RLS com duas identidades | Aprovados |

Os testes de widgets percorrem as principais telas e estados vazios em larguras de 320 e 390 px; verificam navegação, abertura de dispositivo offline e enfileiramento de comando. Os testes de domínio verificam ocupação, encerramento com relatório, criação de evento sem leituras fabricadas e manutenção do estado offline após pedido de reinício. O teste PDF gera bytes de um documento real com fontes incorporadas.

O teste SQL usa um schema `auth` mínimo e roles locais para exercitar a migração: criação de exemplos, snapshot de relatórios, isolamento de leitura e atualização, proibição de spoof de proprietário e vínculos entre contas, idempotência do seed e bloqueio de escrita em relatórios/conclusão de comandos pelo cliente.

Não foram usados projeto, credenciais, e-mail transacional ou sensores reais do usuário. Login por e-mail, entrega de mensagens de recuperação, transporte Realtime, consumo de comandos pelo hardware e PDF via diálogo nativo ainda precisam de verificação no seu ambiente. Android APK e iOS não foram compilados nem assinados neste ambiente.

A fidelidade visual foi aproximada a partir das capturas e da spec. As fotografias e a marca original em vetor não estavam disponíveis como assets separados; não há comparação pixel a pixel com o Figma original.
