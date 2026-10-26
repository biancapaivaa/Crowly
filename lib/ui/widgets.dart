import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme.dart';

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = 14,
    this.color = C.surface,
    this.border,
    this.onTap,
  });
  final Widget child;
  final double padding;
  final Color color;
  final Color? border;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: border ?? C.raised),
    ),
    clipBehavior: Clip.antiAlias,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: EdgeInsets.all(padding), child: child),
      ),
    ),
  );
}

class Brand extends StatelessWidget {
  const Brand({super.key, this.size = 25});
  final double size;
  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        const TextSpan(text: 'CRO'),
        TextSpan(
          text: 'W',
          style: const TextStyle(color: Colors.white),
        ),
        const TextSpan(text: 'LY'),
      ],
    ),
    style: TextStyle(color: Colors.white, 
      fontFamily: 'CrowlyCondensed',
      fontSize: size,
      fontWeight: FontWeight.w900,
      letterSpacing: 2.4,
      height: 1.2,
    ),
  );
}

class BrandSymbol extends StatelessWidget {
  const BrandSymbol({super.key, this.size = 145});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Símbolo Crowly',
    child: CustomPaint(size: Size.square(size), painter: _BrandPainter()),
  );
}

class _BrandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.scale(s.width / 160, s.height / 160);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [C.pink, C.violet],
      ).createShader(const Rect.fromLTWH(0, 0, 160, 160));
    canvas.drawArc(
      const Rect.fromLTWH(10, 10, 120, 140),
      -.82,
      -4.65,
      false,
      p,
    );
    p.style = PaintingStyle.fill;
    for (final t in [
      (54.0, 65.0, 8.0, 38.0),
      (76.0, 53.0, 10.0, 58.0),
      (97.0, 65.0, 7.0, 37.0),
    ]) {
      canvas.drawCircle(Offset(t.$1, t.$2), t.$3, p);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(t.$1 - t.$3, t.$2 + 12, t.$3 * 2, t.$4),
          const Radius.circular(8),
        ),
        p,
      );
    }
    final colors = [C.pink, C.yellow, C.violet];
    for (var i = 0; i < 3; i++) {
      final y = 76.0 + i * 18;
      final wire = Paint()
        ..color = colors[i]
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(
        Path()
          ..moveTo(98, y)
          ..lineTo(114, y)
          ..lineTo(128, y - 12)
          ..lineTo(151, y - 12),
        wire,
      );
      canvas.drawCircle(Offset(152, y - 12), 4, wire);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Section extends StatelessWidget {
  const Section(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.color = C.violet});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(.18),
      border: Border.all(color: color.withOpacity(.45)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
    ),
  );
}

class FilterStrip extends StatelessWidget {
  const FilterStrip({
    super.key,
    required this.labels,
    required this.value,
    required this.onChanged,
    this.color = C.pink,
  });
  final List<String> labels;
  final int value;
  final ValueChanged<int> onChanged;
  final Color color;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: List.generate(
        labels.length,
        (i) => Padding(
          padding: const EdgeInsets.only(right: 7),
          child: ChoiceChip(
            label: Text(labels[i]),
            selected: i == value,
            onSelected: (_) => onChanged(i),
            showCheckmark: false,
            selectedColor: color,
            backgroundColor: C.surface,
            side: const BorderSide(color: C.raised),
            shape: const StadiumBorder(),
            labelStyle: TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    ),
  );
}

class Metric extends StatelessWidget {
  const Metric(
    this.label,
    this.value, {
    super.key,
    this.icon,
    this.color = C.violet,
    this.progress,
  });
  final String label, value;
  final IconData? icon;
  final Color color;
  final double? progress;
  @override
  Widget build(BuildContext context) => Panel(
    padding: 10,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 8),
        ],
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        if (progress != null) ...[
          const SizedBox(height: 8),
          Progress(progress!, color: C.pink),
        ],
      ],
    ),
  );
}

class Metrics extends StatelessWidget {
  const Metrics(this.children, {super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: children[i]),
        ],
      ],
    ),
  );
}

class Progress extends StatelessWidget {
  const Progress(this.value, {super.key, this.color = C.violet});
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(9),
    child: LinearProgressIndicator(
      value: value.clamp(0, 1),
      color: color,
      backgroundColor: C.nav,
      minHeight: 6,
    ),
  );
}

class KeyValue extends StatelessWidget {
  const KeyValue(this.label, this.value, {super.key, this.color});
  final String label, value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

Color severityColor(String s) => switch (s) {
  'emergency' => C.red,
  'high' => C.pink,
  'medium' => C.yellow,
  _ => C.violet,
};

class AlertTile extends StatelessWidget {
  const AlertTile(this.alert, {super.key, this.onTap, this.showStatus = false});
  final CrowlyRow alert;
  final VoidCallback? onTap;
  final bool showStatus;
  @override
  Widget build(BuildContext context) {
    final severity = severityColor(alert.text('severity'));
    final status = alert.text('status');
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Panel(
        padding: 11,
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: severity.withOpacity(.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: severity,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.text('title'),
                    style: const TextStyle(color: Colors.white, 
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${alert.text('description')} • ${relativeTime(alert['created_at'] as String?)}',
                    style: const TextStyle(fontSize: 9, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Pill(
              showStatus && status != 'open'
                  ? statusLabel(status)
                  : severityLabel(alert.text('severity')),
              color: showStatus && status == 'resolved'
                  ? C.green
                  : showStatus && status == 'reviewing'
                  ? C.yellow
                  : severity,
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, size: 16, color: C.muted),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.description,
    required this.action,
    required this.onAction,
    this.icon = Icons.query_stats,
    this.brand = false,
  });
  final String title, description, action;
  final VoidCallback onAction;
  final IconData icon;
  final bool brand;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 12),
    child: Column(
      children: [
        if (brand)
          const BrandSymbol(size: 125)
        else
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: C.violet.withOpacity(.06),
              border: Border.all(color: C.violet.withOpacity(.15)),
            ),
            child: Center(
              child: Container(
                width: 83,
                height: 83,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: C.violet.withOpacity(.12),
                  border: Border.all(color: C.violet),
                ),
                child: Icon(icon, color: C.violet, size: 35),
              ),
            ),
          ),
        const SizedBox(height: 25),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(onPressed: onAction, child: Text(action)),
        ),
      ],
    ),
  );
}

class DataChart extends StatelessWidget {
  const DataChart(
    this.points, {
    super.key,
    this.bars = false,
    this.occupancyOnly = false,
  });
  final List<CrowlyRow> points;
  final bool bars, occupancyOnly;
  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'Sem leituras no período',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 130,
          width: double.infinity,
          child: CustomPaint(
            painter: _ChartPainter(points, bars, occupancyOnly),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: points
              .map(
                (p) => Text(
                  '${p.date('recorded_at').hour}h',
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
              )
              .toList(),
        ),
        if (!occupancyOnly)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Pill('Entradas', color: C.pink),
                SizedBox(width: 8),
                Pill('Saídas'),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.points, this.bars, this.occupancyOnly);
  final List<CrowlyRow> points;
  final bool bars, occupancyOnly;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = C.raised
      ..strokeWidth = 1;
    for (var i = 1; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final series = occupancyOnly ? ['occupancy'] : ['entries', 'exits'];
    var maxValue = 1.0;
    for (final p in points) {
      for (final key in series) {
        maxValue = math.max(maxValue, p.number(key));
      }
    }
    for (var k = 0; k < series.length; k++) {
      final color = occupancyOnly
          ? C.violet
          : k == 0
          ? C.pink
          : C.violet;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      final path = Path();
      for (var i = 0; i < points.length; i++) {
        final x = bars
            ? size.width * (i + .5) / points.length
            : points.length == 1
            ? size.width / 2
            : size.width * i / (points.length - 1);
        final y =
            size.height -
            (points[i].number(series[k]) / maxValue) * (size.height - 12);
        if (bars) {
          final width = size.width / points.length / 3;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                x + (k - .9) * width,
                y,
                width * .85,
                size.height - y,
              ),
              const Radius.circular(2),
            ),
            Paint()..color = color,
          );
        } else {
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
          canvas.drawCircle(Offset(x, y), 2.5, Paint()..color = color);
        }
      }
      if (!bars) canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String description,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ??
    false;
void toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 96),
        content: Text(message),
      ),
    );
Future<void> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (context.mounted && success != null) toast(context, success);
  } catch (e) {
    if (context.mounted) toast(context, 'Não foi possível concluir: $e');
  }
}


class AdminOnly extends StatelessWidget {
  const AdminOnly({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.lock_outline, color: Colors.white, size: 32),
      SizedBox(height: 12),
      Text('Acesso exclusivo do administrador', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    ]),
  );
}
