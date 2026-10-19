import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/store.dart';
import 'widgets.dart';
import 'iot.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.store, this.onLogout});
  final CrowlyStore store;
  final Future<void> Function()? onLogout;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, phone, organization, role;
  late bool alerts, summaries;
  late int avatar;
  bool busy = false;
  static const colors = [C.violet, C.pink, C.blue, Color(0xFF176B50)];
  @override
  void initState() {
    super.initState();
    final p = widget.store.profile;
    name = TextEditingController(text: p['full_name'] as String? ?? '');
    phone = TextEditingController(text: p['phone'] as String? ?? '');
    organization = TextEditingController(text: p['organization'] as String? ?? '');
    role = TextEditingController(text: p['role'] as String? ?? '');
    alerts = p['profile_alerts'] != false;
    summaries = p['profile_summaries'] == true;
    avatar = ((p['avatar_color'] as num?)?.toInt() ?? 0).clamp(0, 3);
    name.addListener(refresh);
  }
  void refresh() { if (mounted) setState(() {}); }
  @override
  void dispose() {
    name.removeListener(refresh);
    for (final c in [name, phone, organization, role]) { c.dispose(); }
    super.dispose();
  }
  void message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await widget.store.saveProfile({
        'full_name': name.text.trim(), 'phone': phone.text.trim(),
        'organization': organization.text.trim(), 'role': role.text.trim(),
        'profile_alerts': alerts, 'profile_summaries': summaries, 'avatar_color': avatar,
      });
      if (mounted) message(widget.store.demo ? 'Perfil atualizado nesta demonstração.' : 'Perfil salvo com sucesso.');
    } catch (_) { if (mounted) message('Não foi possível salvar. Verifique a conexão e tente novamente.'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> resetPassword() async {
    final email = widget.store.client?.auth.currentUser?.email;
    if (email == null || busy) return;
    setState(() => busy = true);
    try {
      await widget.store.client!.auth.resetPasswordForEmail(email);
      if (mounted) message('Enviamos o link de recuperação para seu e-mail.');
    } catch (_) { if (mounted) message('Não foi possível enviar o link. Tente novamente.'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final words = name.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final initials = words.isEmpty ? 'CR' : words.take(2).map((w) => w.characters.first).join().toUpperCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil'), backgroundColor: C.background, foregroundColor: Colors.white),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: CircleAvatar(radius: 40, backgroundColor: colors[avatar], child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)))),
          const SizedBox(height: 12),
          Text(name.text.trim().isEmpty ? 'Seu perfil' : name.text.trim(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(store.demo ? 'Conta de demonstração' : store.client?.auth.currentUser?.email ?? '', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text('Cor do avatar', textAlign: TextAlign.center),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(colors.length, (i) => IconButton(
            tooltip: 'Cor do avatar ${i + 1}', onPressed: busy ? null : () => setState(() => avatar = i),
            icon: Container(width: 28, height: 28, decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle, border: Border.all(color: Colors.white, width: avatar == i ? 3 : 0)), child: avatar == i ? const Icon(Icons.check, size: 17, color: Colors.white) : null),
          ))),
          const Section('Dados pessoais'),
          Panel(child: Column(children: [
            field(name, 'Nome completo', Icons.person_outline, required: true),
            const SizedBox(height: 14),
            TextFormField(initialValue: store.demo ? 'demo@crowly.app' : store.client?.auth.currentUser?.email ?? '', readOnly: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'E-mail da conta', prefixIcon: Icon(Icons.email_outlined), helperText: 'E-mail utilizado para entrar na conta.')),
            const SizedBox(height: 14),
            field(phone, 'Telefone', Icons.phone_outlined, keyboard: TextInputType.phone),
            const SizedBox(height: 14), field(organization, 'Organização', Icons.business_outlined),
            const SizedBox(height: 14), field(role, 'Cargo ou função', Icons.badge_outlined),
          ])),
          const Section('Minha atividade'),
          Panel(child: Wrap(spacing: 24, runSpacing: 16, children: [
            activity('Eventos', store.rows('events').length), activity('Dispositivos', store.rows('devices').length), activity('Relatórios', store.rows('reports').length),
          ])),
          const Section('Preferências'),
          Panel(child: Column(children: [
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Alertas no aplicativo'), value: alerts, onChanged: busy ? null : (v) => setState(() => alerts = v)),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Resumos de eventos'), value: summaries, onChanged: busy ? null : (v) => setState(() => summaries = v)),
            const Text('As preferências são salvas no perfil. O envio de notificações e resumos depende da configuração do serviço.'),
          ])),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: busy ? null : save, icon: const Icon(Icons.save_outlined), label: Text(busy ? 'Aguarde...' : 'Salvar alterações')),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => IoTPage(store: store))), icon: const Icon(Icons.sensors), label: const Text('Conectar ESP32')),
          const Section('Segurança e conta'),
          Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Seus eventos e dispositivos ficam vinculados à sua conta.'),
            const SizedBox(height: 12),
            if (store.demo) const Text('No modo demo, as alterações ficam disponíveis apenas durante a sessão.')
            else OutlinedButton.icon(onPressed: busy ? null : resetPassword, icon: const Icon(Icons.lock_reset), label: const Text('Redefinir senha por e-mail')),
            if (!store.demo && store.rows('events').isEmpty) OutlinedButton(onPressed: busy ? null : () => runAction(context, store.seed, success: 'Exemplos adicionados.'), child: const Text('Adicionar eventos de exemplo')),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: busy || widget.onLogout == null ? null : () => runAction(context, widget.onLogout!), icon: const Icon(Icons.logout), label: const Text('Sair da conta')),
          ])),
        ])),
      )))),
    );
  }
  Widget field(TextEditingController controller, String label, IconData icon, {bool required = false, TextInputType? keyboard}) => TextFormField(
    controller: controller, enabled: !busy, keyboardType: keyboard, maxLength: label == 'Telefone' ? 30 : 100,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), counterText: ''),
    validator: (value) => required && (value == null || value.trim().isEmpty) ? 'Informe seu nome completo.' : null,
  );
  Widget activity(String label, int value) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$value', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), Text(label)]);
}
