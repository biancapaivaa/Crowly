import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../data/store.dart';
import 'widgets.dart';

class IoTPage extends StatefulWidget {
  const IoTPage({super.key, required this.store});
  final CrowlyStore store;
  @override
  State<IoTPage> createState() => _IoTPageState();
}
class _IoTPageState extends State<IoTPage> {
  String? eventId;
  String? token;
  String? error;
  bool busy = false;
  Future<void> pair() async {
    if (eventId == null) return;
    if (token != null) {
      final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Gerar nova credencial?'),
        content: const Text('Isso invalida a credencial anterior deste evento. Atualize o config.h do Wokwi com a nova.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gerar'))],
      ));
      if (ok != true || !mounted) return;
    }
    setState(() { busy = true; error = null; });
    try {
      final result = await widget.store.client!.rpc('crowly_pair', params: {'target_event': eventId});
      if (mounted) setState(() => token = (result as Map)['device_token'] as String);
      if (eventId != null) widget.store.selectEvent(eventId!);
      await widget.store.load();
    } catch (_) {
      if (mounted) setState(() => error = 'Nao foi possivel vincular. Confira o SQL complementar, sua conexao e o estado do evento.');
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final events = widget.store.rows('events').where((e) => ['live','scheduled'].contains(e.text('status'))).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Conectar ESP32'), foregroundColor: Colors.white, backgroundColor: C.background),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: SingleChildScrollView(
        padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Wokwi → Supabase → Crowly', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Aplique primeiro o SQL 202610190001_iot.sql. Cada evento aceita uma placa neste prototipo. Gerar a credencial novamente desconecta a placa anterior do evento.'),
          const SizedBox(height: 20),
          if (widget.store.demo) const Text('Saia do modo demo e entre na sua conta Supabase para conectar sensores.')
          else if (events.isEmpty) const Text('Crie um evento na aba Eventos antes de continuar.')
          else ...[
            DropdownButtonFormField<String>(
              initialValue: eventId, isExpanded: true,
              decoration: const InputDecoration(labelText: 'Evento'),
              dropdownColor: C.raised, style: const TextStyle(color: Colors.white),
              items: events.map((e) => DropdownMenuItem(value: e.text('id'), child: Text(e.text('title'), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: busy || token != null ? null : (v) => setState(() => eventId = v),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: busy || eventId == null ? null : pair, child: Text(busy ? 'Vinculando...' : token == null ? 'Gerar credencial do ESP32' : 'Gerar nova credencial')),
          ],
          if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!)),
          if (token != null) ...[
            const Section('Copie para o config.h'),
            Panel(child: SelectableText('const char* DEVICE_TOKEN = "$token";', style: const TextStyle(color: Colors.white, fontFamily: 'monospace'))),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: () async {
              await Clipboard.setData(ClipboardData(text: token!));
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credencial copiada.')));
            }, icon: const Icon(Icons.copy), label: const Text('Copiar credencial')),
            const Text('Guarde a credencial no config.h. Ela aparece somente nesta tela e permite enviar dados para este evento. Evite publicar uma credencial ativa em projetos publicos; gere outra para revogar a anterior.'),
            const SizedBox(height: 16),
            const Text('Depois, abra o evento no app e inicie o monitoramento. Execute o Wokwi. As leituras chegarao a cada 10 segundos do tempo simulado. O envio HTTPS pode demorar mais na simulacao.'),
          ],
        ]),
      )))),
    );
  }
}
