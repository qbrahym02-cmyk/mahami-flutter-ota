import 'package:flutter/material.dart';

/// إعلان يتحكم به المطوّر من ملف config.json عن بُعد.
class AnnouncementBanner extends StatelessWidget {
  final String text;
  final String type;
  const AnnouncementBanner({super.key, required this.text, required this.type});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg, IconData icon) = switch (type) {
      'warning' => (scheme.errorContainer, scheme.onErrorContainer,
          Icons.warning_amber_rounded),
      'success' => (scheme.tertiaryContainer, scheme.onTertiaryContainer,
          Icons.celebration_outlined),
      _ => (scheme.secondaryContainer, scheme.onSecondaryContainer,
          Icons.campaign_outlined),
    };
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Icon(icon, color: fg),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: fg))),
        ]),
      ),
    );
  }
}
