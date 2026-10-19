import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme.dart';
import 'widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.client,
    required this.onDemo,
    this.configurationError,
  });
  final SupabaseClient? client;
  final VoidCallback onDemo;
  final String? configurationError;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      confirmation = TextEditingController();
  bool register = false, hidden = true, confirmationHidden = true, busy = false;
  String? message;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      if (register) {
        final response = await widget.client!.auth.signUp(
          email: email.text.trim(),
          password: password.text,
          data: {'full_name': name.text.trim()},
        );
        if (mounted && response.session == null) {
          setState(
            () => message = 'Conta criada. Confirme seu e-mail para entrar.',
          );
        }
      } else {
        await widget.client!.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => message = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => message = 'Falha na conexão. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> reset() async {
    if (!email.text.contains('@')) {
      toast(context, 'Informe seu e-mail no campo acima.');
      return;
    }
    await runAction(
      context,
      () => widget.client!.auth.resetPasswordForEmail(
        email.text.trim(),
        redirectTo: 'io.crowly.app://login-callback/',
      ),
      success:
          'Se a conta existir, você receberá o link de recuperação por e-mail.',
    );
  }

  Widget field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool secret = false,
    bool confirmField = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      obscureText: secret && (confirmField ? confirmationHidden : hidden),
      keyboardType: label == 'E-mail'
          ? TextInputType.emailAddress
          : TextInputType.text,
      autocorrect: !secret,
      enableSuggestions: !secret,
      autofillHints: label == 'E-mail'
          ? const [AutofillHints.email]
          : secret
          ? [register ? AutofillHints.newPassword : AutofillHints.password]
          : const [AutofillHints.name],
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, size: 19),
        suffixIcon: secret
            ? IconButton(
                tooltip: 'Mostrar ou ocultar senha',
                onPressed: () => setState(() {
                  if (confirmField) {
                    confirmationHidden = !confirmationHidden;
                  } else {
                    hidden = !hidden;
                  }
                }),
                icon: Icon(
                  (confirmField ? confirmationHidden : hidden)
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                ),
              )
            : null,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Preencha este campo';
        if (label == 'E-mail' &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) {
          return 'Informe um e-mail válido';
        }
        if (secret && register && v.length < 8) {
          return 'Use pelo menos 8 caracteres';
        }
        if (confirmField && v != password.text) {
          return 'As senhas não coincidem';
        }
        return null;
      },
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const SizedBox(height: 12),
                const BrandSymbol(size: 156),
                const SizedBox(height: 22),
                const Brand(size: 29),
                const SizedBox(height: 25),
                const Text(
                  'Feito para os seus melhores dias',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  register ? 'Crie uma conta!' : 'Bem-vindo de volta!',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 7),
                Text(
                  register
                      ? 'Preencha os dados pra começar'
                      : 'Entre com suas credenciais',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 25),
                Panel(
                  padding: 18,
                  child: Form(
                    key: form,
                    child: Column(
                      children: [
                        if (register)
                          field(name, 'Nome completo', Icons.person_outline),
                        field(email, 'E-mail', Icons.mail_outline),
                        field(
                          password,
                          'Senha',
                          Icons.lock_outline,
                          secret: true,
                        ),
                        if (register)
                          field(
                            confirmation,
                            'Confirmar senha',
                            Icons.lock_outline,
                            secret: true,
                            confirmField: true,
                          ),
                        if (!register)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: widget.client == null || busy
                                  ? null
                                  : reset,
                              child: const Text('Esqueceu a senha?'),
                            ),
                          ),
                        if (message != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              message!,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: busy || widget.client == null
                                ? null
                                : submit,
                            child: busy
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Entrar'),
                          ),
                        ),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              register
                                  ? 'Já tem uma conta?'
                                  : 'Não tem uma conta?',
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                            TextButton(
                              onPressed: busy
                                  ? null
                                  : () => setState(() {
                                      register = !register;
                                      message = null;
                                      form.currentState?.reset();
                                    }),
                              child: Text(register ? 'Logar' : 'Cadastre-se'),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Termos de Uso'),
                              content: const Text(
                                'Versão de desenvolvimento do Crowly. Os termos definitivos e a política de privacidade devem ser fornecidos pelo responsável pelo aplicativo antes da publicação.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Fechar'),
                                ),
                              ],
                            ),
                          ),
                          child: const Text.rich(
                            TextSpan(
                              text: 'Ao continuar, você concorda com os ',
                              style: TextStyle(fontSize: 9, color: Colors.white),
                              children: [
                                TextSpan(
                                  text: 'Termos de Uso',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.client == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      widget.configurationError ??
                          'Configure o Supabase para entrar ou explore a demonstração.',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                TextButton(
                  onPressed: busy ? null : widget.onDemo,
                  child: const Text('Explorar demonstração'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class PasswordRecovery extends StatefulWidget {
  const PasswordRecovery({
    super.key,
    required this.client,
    required this.onDone,
  });
  final SupabaseClient client;
  final VoidCallback onDone;
  @override
  State<PasswordRecovery> createState() => _PasswordRecoveryState();
}

class _PasswordRecoveryState extends State<PasswordRecovery> {
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Brand(),
                const Section('Defina sua nova senha'),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nova senha'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmation,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirme a senha',
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          if (password.text.length < 8 ||
                              password.text != confirmation.text) {
                            toast(
                              context,
                              'Use pelo menos 8 caracteres e confirme a mesma senha.',
                            );
                            return;
                          }
                          setState(() => busy = true);
                          try {
                            await widget.client.auth.updateUser(
                              UserAttributes(password: password.text),
                            );
                            widget.onDone();
                          } catch (e) {
                            if (context.mounted) {
                              toast(context, 'Não foi possível alterar: $e');
                            }
                          } finally {
                            if (mounted) setState(() => busy = false);
                          }
                        },
                  child: Text(busy ? 'Salvando...' : 'Salvar senha'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
