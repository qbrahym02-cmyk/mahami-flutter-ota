import 'package:flutter/material.dart';

import '../services/update_service.dart';

/// شريط يظهر أعلى الشاشة عند توفر نسخة جديدة، مع زر تحديث وشريط تقدّم.
class UpdateBanner extends StatelessWidget {
  final UpdateService updates;
  const UpdateBanner({super.key, required this.updates});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: updates,
      builder: (context, _) {
        if (!updates.shouldShowBanner) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        final v = updates.latest;

        Widget body;
        switch (updates.state) {
          case UpdateState.downloading:
            body = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('جارِ تنزيل التحديث... ${(updates.progress * 100).round()}%'),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: updates.progress),
              ],
            );
          case UpdateState.installing:
            body = const Text('جارِ فتح شاشة التثبيت...');
          case UpdateState.error:
            body = Row(children: [
              Expanded(child: Text(updates.error ?? 'حدث خطأ')),
              TextButton(
                  onPressed: updates.downloadAndInstall,
                  child: const Text('إعادة المحاولة')),
              IconButton(
                  onPressed: updates.dismiss, icon: const Icon(Icons.close)),
            ]);
          default:
            body = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.system_update, color: scheme.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'نسخة جديدة متوفرة: ${v?.versionName} (${v?.buildNumber})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (v?.mandatory != true)
                    IconButton(
                        onPressed: updates.dismiss,
                        icon: const Icon(Icons.close)),
                ]),
                if ((v?.changelog ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Text(v!.changelog),
                  ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FilledButton.icon(
                    onPressed: updates.downloadAndInstall,
                    icon: const Icon(Icons.download),
                    label: const Text('حدّث الآن'),
                  ),
                ),
              ],
            );
        }

        return Card(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          color: scheme.primaryContainer,
          child: Padding(padding: const EdgeInsets.all(12), child: body),
        );
      },
    );
  }
}
