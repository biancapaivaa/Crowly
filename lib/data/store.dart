import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/models.dart';
import 'demo.dart';

class CrowlyStore extends ChangeNotifier {
  CrowlyStore({this.client, this.demo = false, this.demoRole = 'admin'}) {
    if (demo) {
      data = demoData();
      accountLoaded = true;
      member = {'id':'demo', 'workspace_id':'demo', 'role':demoRole, 'enabled':true};
    }
  }
  final SupabaseClient? client;
  final bool demo;
  final String demoRole;
  Map<String, dynamic>? member;
  bool accountLoaded = false;
  bool get hasAccess => member != null && member!['enabled'] == true;
  bool get isAdmin => hasAccess && member!['role'] == 'admin';
  String get roleLabel => isAdmin ? 'Administrador' : 'Funcionário';
  List<Map<String,dynamic>> demoEmployees = [];
  Future<List<Map<String,dynamic>>> employees() async {
    if (!isAdmin) throw StateError('Acesso exclusivo do administrador.');
    if (demo) return List.of(demoEmployees);
    final rows = await client!.from('crowly_members').select('id,full_name,email,role,enabled,created_at').eq('workspace_id', member!['workspace_id']).eq('role','staff').order('created_at',ascending:false);
    return rows.map((r) => Map<String,dynamic>.from(r)).toList();
  }
  Future<void> createEmployee(String name, String email, String password) async {
    if (!isAdmin) throw StateError('Acesso exclusivo do administrador.');
    if (demo) {
      if (demoEmployees.any((m) => m['email'] == email)) throw StateError('E-mail já cadastrado.');
      demoEmployees.insert(0, {'id':'staff-${DateTime.now().microsecondsSinceEpoch}','full_name':name,'email':email,'role':'staff','enabled':true});
      _emit();
      return;
    }
    final response = await client!.functions.invoke('crowly-create-employee', body:{'full_name':name,'email':email,'password':password});
    if (response.status != 201) throw StateError('Não foi possível cadastrar o funcionário.');
  }
  Future<void> Function()? onLogout;
  Map<String, dynamic> demoProfile = {};
  Map<String, dynamic> get profile => demo ? demoProfile : Map<String, dynamic>.from(client?.auth.currentUser?.userMetadata ?? {});
  Future<void> saveProfile(Map<String, dynamic> values) async {
    if (demo) {
      demoProfile = {...demoProfile, ...values};
    } else {
      await client!.auth.updateUser(UserAttributes(data: values));
    }
    _emit();
  }

  Map<String, List<CrowlyRow>> data = {};
  bool loading = false;
  String? error;
  String? selectedEventId;
  RealtimeChannel? _channel;
  Timer? _debounce;
  Timer? _poll;
  bool _disposed = false;
  int _generation = 0;
  static const tables = [
    'events',
    'areas',
    'devices',
    'alerts',
    'samples',
    'reports',
    'commands',
  ];
  List<CrowlyRow> rows(String table) => table == 'reports' && !isAdmin ? [] : data[table] ?? [];
  List<CrowlyRow> forEvent(String table, String id) {
    final result = rows(table).where((r) => r.text('event_id') == id).toList();
    if (table == 'samples') {
      result.sort(
        (a, b) => a.text('recorded_at').compareTo(b.text('recorded_at')),
      );
    } else if (table == 'areas') {
      result.sort(
        (a, b) => a.integer('position').compareTo(b.integer('position')),
      );
    }
    return result;
  }

  CrowlyRow? get activeEvent {
    final selected = rows('events').where(
      (e) => e.text('id') == selectedEventId && e.text('status') == 'live',
    );
    if (selected.isNotEmpty) return selected.first;
    final live = rows('events').where((e) => e.text('status') == 'live');
    return live.isEmpty ? null : live.first;
  }

  void selectEvent(String id) {
    selectedEventId = id;
    _emit();
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    final generation = ++_generation;
    loading = true;
    error = null;
    _emit();
    try {
      if (!demo) {
        final user = client!.auth.currentUser;
        final fresh = user == null ? null : await client!.from('crowly_members').select().eq('id', user.id).maybeSingle();
        if (_disposed || generation != _generation) return;
        member = fresh == null ? null : Map<String,dynamic>.from(fresh);
        accountLoaded = true;
        if (!hasAccess) {
          data = {};
          return;
        }
        if (!isAdmin) data.remove('reports');
        _emit();
        final allowedTables = tables.where((t) => t != 'reports' || isAdmin).toList();
        final values = await Future.wait(allowedTables.map((t) => client!.from(t).select()));
        if (_disposed || generation != _generation) return;
        data = {
          for (var i = 0; i < allowedTables.length; i++)
            allowedTables[i]: values[i].map((v) => CrowlyRow.from(v)).toList(),
        };
      }
    } catch (e) {
      if (generation == _generation) {
        member = null;
        accountLoaded = true;
        data = {};
        error =
            'Não foi possível carregar seus eventos. Verifique a conexão e tente novamente.';
      }
    } finally {
      if (generation == _generation) {
        loading = false;
        _emit();
      }
    }
  }

  Future<void> connect() async {
    await load();
    if (_disposed || demo || client!.auth.currentUser == null) return;
    _channel = client!.channel('crowly-${client!.auth.currentUser!.id}');
    for (final table in [...tables, 'crowly_members']) {
      _channel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 350), load);
        },
      );
    }
    _channel!.subscribe();
    // Realtime e a via principal; polling cobre desconexoes do WebSocket.
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_disposed && !loading) unawaited(load());
    });
  }

  Future<void> seed() async {
    if (!demo) await client!.rpc('seed_my_demo');
    await load();
  }

  Future<void> createEvent({
    required String title,
    required String location,
    required DateTime start,
    required DateTime end,
    required int capacity,
    ({Uint8List bytes, String contentType})? photo,
    CrowlyRow? event,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'location': location,
      'starts_at': start.toUtc().toIso8601String(),
      'ends_at': end.toUtc().toIso8601String(),
      'capacity': capacity,
    };
    final id = event?.text('id');
    if (demo) {
      if (photo != null) payload['photo_bytes'] = photo.bytes;
      if (id == null) {
        rows('events').add({
          ...payload,
          'id': 'event-${DateTime.now().microsecondsSinceEpoch}',
          'status': 'scheduled',
          'people': 0,
          'entries': 0,
          'exits': 0,
        });
      } else {
        rows('events').firstWhere((row) => row.text('id') == id).addAll(payload);
      }
      _emit();
      return;
    }

    final bucket = client!.storage.from('crowly-event-photos');
    String? uploadedPath;
    if (photo != null) {
      final random = Random.secure();
      final key = base64UrlEncode(List.generate(18, (_) => random.nextInt(256)));
      uploadedPath = "${member!['workspace_id']}/$key";
      await bucket.uploadBinary(
        uploadedPath,
        photo.bytes,
        fileOptions: FileOptions(contentType: photo.contentType),
      );
      payload['image_url'] = bucket.getPublicUrl(uploadedPath);
    }

    try {
      if (id == null) {
        await client!.from('events').insert(payload);
      } else {
        var update = client!.from('events').update(payload).eq('id', id);
        if (uploadedPath != null) {
          final previous = event!['image_url'];
          if (previous == null) {
            update = update.isFilter('image_url', null);
          } else {
            update = update.eq('image_url', previous);
          }
        }
        final saved = await update.select('id').maybeSingle();
        if (saved == null) {
          throw StateError('O evento mudou. Abra os detalhes e tente novamente.');
        }
      }
    } catch (error) {
      // Preserve the upload if a network failure leaves the database result unknown.
      if (uploadedPath != null &&
          (error is PostgrestException || error is StateError)) {
        await _removeEventPhoto(bucket.getPublicUrl(uploadedPath));
      }
      rethrow;
    }
    if (uploadedPath != null && event != null) {
      await _removeEventPhoto(event.text('image_url'));
    }
    await load();
  }

  Future<void> deleteEvent(String id) async {
    if (demo) {
      rows('events').removeWhere((row) => row.text('id') == id);
      for (final table in tables.where((table) => table != 'events')) {
        data[table]?.removeWhere((row) => row.text('event_id') == id);
      }
      if (selectedEventId == id) selectedEventId = null;
      _emit();
      return;
    }
    final deleted = await client!
        .from('events')
        .delete()
        .eq('id', id)
        .select('image_url')
        .maybeSingle();
    if (deleted == null) throw StateError('Evento não encontrado.');
    if (selectedEventId == id) selectedEventId = null;
    await _removeEventPhoto(deleted.text('image_url'));
    await load();
  }

  Future<void> _removeEventPhoto(String url) async {
    final bucket = client!.storage.from('crowly-event-photos');
    final prefix = bucket.getPublicUrl("${member?['workspace_id']}/");
    if (!url.startsWith(prefix)) return;
    final key = url.substring(prefix.length);
    if (!RegExp(r'^[a-zA-Z0-9_-]{24}$').hasMatch(key)) return;
    try {
      await bucket.remove(["${member!['workspace_id']}/$key"]);
    } catch (error) {
      debugPrint('Falha ao remover a foto anterior do evento: $error');
    }
  }

  Future<void> eventStatus(CrowlyRow event, String status) async {
    if (status == 'live') selectedEventId = event.text('id');
    if (demo) {
      event['status'] = status;
      if (status == 'ended' && forEvent('reports', event.text('id')).isEmpty) {
        final points = forEvent('samples', event.text('id'));
        final occ = points.map((p) => p.number('occupancy')).toList();
        rows('reports').add({
          'id': 'report-${event.text('id')}',
          'event_id': event.text('id'),
          'total_entries': event.integer('entries'),
          'total_exits': event.integer('exits'),
          'average_occupancy': occ.isEmpty
              ? 0
              : occ.reduce((a, b) => a + b) / occ.length,
          'peak_occupancy': occ.isEmpty
              ? 0
              : occ.reduce((a, b) => a > b ? a : b),
          'temperature': 0,
          'humidity': 0,
        });
      }
      _emit();
    } else {
      await client!.rpc(
        'set_event_status',
        params: {'target_event': event.text('id'), 'new_status': status},
      );
      await load();
    }
  }

  Future<void> alertStatus(CrowlyRow alert, String status) async {
    if (demo) {
      alert['status'] = status;
      _emit();
    } else {
      await client!
          .from('alerts')
          .update({'status': status})
          .eq('id', alert.text('id'));
      await load();
    }
  }

  Future<void> command(
    String eventId,
    String kind, {
    String? deviceId,
    String? areaId,
    String? note,
  }) async {
    final payload = <String, dynamic>{
      'event_id': eventId,
      'kind': kind,
      'device_id': deviceId,
      'area_id': areaId,
      'note': note,
      'status': 'queued',
    };
    if (demo) {
      rows(
        'commands',
      ).add({...payload, 'id': 'cmd-${DateTime.now().microsecondsSinceEpoch}'});
      _emit();
    } else {
      await client!.from('commands').insert(payload);
      await load();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _debounce?.cancel();
    _poll?.cancel();
    final channel = _channel;
    if (channel != null) unawaited(client!.removeChannel(channel));
    super.dispose();
  }
}
