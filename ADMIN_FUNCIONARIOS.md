# Crowly — administrador e funcionário

## O que mudou

| Funcionalidade | Administrador | Funcionário |
| --- | --- | --- |
| Home, mapas, calendário e eventos | Sim | Sim |
| Criar/iniciar/encerrar eventos | Sim | Sim |
| Dispositivos, sensores e conexão ESP32 | Sim | Sim |
| Alertas e solicitações de equipe/reinício | Sim | Sim |
| Próprio perfil e recuperação de senha | Sim | Sim |
| Relatórios e exportação PDF | Sim | Não |
| Cadastrar e listar funcionários | Sim | Não |

Os funcionários pertencem à equipe do administrador. Eles operam os mesmos eventos,
dispositivos e alertas. A restrição de relatórios e a autorização de cadastro são
validadas no banco/servidor, além de ocultar os controles na interface.

Não há botão de cadastro público no login. Somente o administrador cria funcionários
no menu **Perfil → Funcionários**. O papel de acesso vem de `crowly_members`;
o campo editável Cargo ou função do perfil não concede permissões.

## 1. Use sua conta atual como primeiro administrador

Use o e-mail da conta que já criou os eventos e vinculou o ESP32. Os eventos atuais
ficam preservados, com os mesmos IDs, e continuam sendo da equipe dessa conta.
Não crie outra conta para o admin se quiser continuar vendo os eventos existentes.

Se for um banco sem usuários, crie a primeira conta em Authentication → Users
ANTES de executar a migração de perfis. Depois da migração, novos usuários são
aceitos apenas pelo cadastro administrativo do app. No seu projeto já existe a
conta usada nos eventos: prefira essa conta atual.

## 2. Execute somente a nova migração

No Supabase, abra SQL Editor → New query. Cole e execute o conteúdo de:

`supabase/migrations/202610260001_roles.sql`

Execute uma vez. A migração usa transação: se houver erro, nenhuma alteração parcial
é aplicada. Não reaplique as migrações antigas, não apague tabelas e não desative RLS.
Ela cria os papéis, protege relatórios/cadastro e compartilha a operação dentro da equipe.
A credencial existente do ESP32 continua válida.

## 3. Defina a conta administradora

Abra `supabase/bootstrap_admin.sql`, troque:

```sql
'COLE_O_EMAIL_DO_ADMIN_AQUI'
```

pelo e-mail da conta atual do app, mantendo as aspas. Cole o script completo no SQL
Editor e execute. Exemplo de substituição: `'admin@exemplo.com'`.
Não preencha com o e-mail de um funcionário. O script não promove uma conta já
cadastrada como funcionário. Os papéis só podem ser configurados por quem administra
o banco, não pelo cliente Flutter.

Se precisar identificar a conta dona de cada evento, execute esta consulta de leitura:

```sql
select e.title, e.owner_id, u.email
from public.events e
join auth.users u on u.id = e.owner_id
order by e.created_at desc;
```

## 4. Publique a função que cria funcionários

As contas são criadas no servidor para não expor chaves privilegiadas no aplicativo.
No painel do Supabase:

1. Abra **Edge Functions** e escolha criar/deploy de função pelo editor.
2. Use exatamente o nome **crowly-create-employee**.
3. Substitua o conteúdo de `index.ts` pelo arquivo completo:
   `supabase/functions/crowly-create-employee/index.ts`.
   Ele é um arquivo único, sem outros arquivos locais para importar.
4. Publique a função.
5. Nas configurações da função, desative a verificação JWT **legada do gateway**
   (`verify_jwt = false`). A função valida a sessão com `auth.getUser()` e confere
   o papel admin ativo no banco antes de cadastrar; a autenticação continua obrigatória.
   Essa configuração evita a rejeição de JWTs assinados com as novas chaves assimétricas.

As variáveis `SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY` são disponibilizadas pelo
ambiente das Edge Functions. Não copie service_role para Flutter, config.local.json
ou Wokwi. Não é necessário enviar essa chave a ninguém.

Se já usa o CLI do Supabase, a alternativa ao editor é executar, na pasta do projeto:

```powershell
npx supabase login
npx supabase functions deploy crowly-create-employee --project-ref rmuhyqjjjrgejycimbho --no-verify-jwt
```

## 5. Desative novos cadastros públicos no painel Auth

Em **Authentication → configuração de Sign In / Providers**, desligue a opção
**Allow new users to sign up**. O nome/seção pode variar no painel.
Mantenha o provedor e-mail/senha habilitado para os usuários entrarem normalmente.
O cadastro administrativo usa a API Admin no servidor. O trigger SQL também bloqueia
cadastros públicos sem provisionamento válido do administrador.

## 6. Atualize e abra o Flutter

Pare o app com Ctrl+C. Substitua a pasta **lib** pela deste pacote. Copie também a
pasta **supabase** e este guia para guardar a configuração. Preserve o seu
**config.local.json**. Você não precisa substituir o config.h do Wokwi nem gerar
outra credencial da placa.

Na pasta do projeto, que contém pubspec.yaml, execute um comando por vez:

```powershell
flutter pub get
flutter run -d chrome --dart-define-from-file=config.local.json
```

Não use DEMO_MODE=true para testar contas reais. Saia e entre novamente com a conta
definida no passo 3. No Perfil, deve aparecer o selo **Administrador**, o botão
**Funcionários** e a aba **Relatórios** na navegação.

## 7. Cadastre os funcionários pelo app

1. Perfil → Funcionários.
2. Informe nome completo e e-mail.
3. Use a senha gerada ou informe outra com pelo menos 12 caracteres. A política
   de senhas configurada no seu Supabase também se aplica.
4. Toque em **Cadastrar funcionário**.
5. Guarde o acesso exibido na confirmação e entregue ao funcionário por um canal privado.

A conta é criada com papel Funcionário e vinculada automaticamente à equipe do
admin. Não promove funcionários a admin, não envia e-mails de convite automaticamente
e não encerra a sessão do administrador durante o cadastro.
O funcionário entra pelo mesmo formulário de login. Ele pode redefinir sua senha
no próprio perfil; mantenha a configuração de e-mail/redirects já descrita no README.
A senha inicial não é gravada em tabelas do app nem nos logs. O Supabase Auth gerencia
a credencial. O administrador não tem uma tela para recuperar a senha depois que a
confirmação é fechada; se necessário, o funcionário usa recuperação de senha.

## 8. Confira os dois acessos

Use uma janela normal para admin e uma janela anônima para funcionário:

- Admin vê relatórios e Perfil → Funcionários.
- Funcionário não vê esses dois acessos. Rotas diretas de relatórios/cadastro também
  são bloqueadas no app. A API de relatórios não retorna linhas para ele.
- Crie um evento em uma conta e confirme que a outra o vê na mesma equipe.
- Ambos podem iniciar/encerrar eventos, tratar alertas, operar dispositivos e vincular ESP32.
- Funcionário não consegue alterar papel/equipe editando o perfil ou user_metadata.

Para conferir o cadastro pelo SQL Editor, sem exibir senhas:

```sql
select id, workspace_id, full_name, email, role, enabled
from public.crowly_members
order by created_at;
```

## Demonstração sem contas reais

```powershell
# Interface do administrador
flutter run -d chrome --dart-define=DEMO_MODE=true --dart-define=DEMO_ROLE=admin

# Interface do funcionário
flutter run -d chrome --dart-define=DEMO_MODE=true --dart-define=DEMO_ROLE=staff
```

No demo, cadastros ficam apenas na memória. O papel do demo não muda as permissões
reais do banco; no modo conectado, o papel sempre vem de crowly_members.

## Validação

- 23 verificações PostgreSQL embarcado aprovadas: migração preservando registros,
  cadastro público bloqueado, isolamento de equipes, relatório restrito mesmo com
  política permissiva legada, comandos, encerramento por funcionário, proteção de
  papel, sincronização de perfil e manutenção da ingestão ESP32.
- 13 verificações da função de cadastro aprovadas, incluindo JWT ausente/inválido,
  funcionário com papel forjado, admin autorizado, campos inválidos, papel/equipe
  fixados pelo servidor e ausência de senha na resposta.
- Sintaxe Dart conferida. Testes Flutter específicos estão em test/roles_test.dart.
- O SDK Flutter não está instalado nesta sessão: análise de tipos, testes Flutter e
  build desta atualização ainda precisam ser executados no ambiente Flutter.
- Nenhuma migração foi aplicada nem função publicada no seu Supabase por esta entrega.

Para repetir os testes de banco e função sem tocar no Supabase real, com Node.js instalado:

```powershell
cd checks/admin
npm ci
npm test
```

Os testes usam PostgreSQL embarcado e um adaptador Auth simulado; não usam credenciais
do seu projeto. Para os testes Flutter, execute `flutter test` na raiz do app.
