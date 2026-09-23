import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/utils/string_extension.dart';
import 'package:nordplayer/ui/settings/about/about_viewmodel.dart';
import 'package:nordplayer/ui/shared/ui/frosted_glass.dart';

class LicensesView extends ConsumerWidget {
  const LicensesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uiState = ref.watch(aboutViewModelProvider);
    final packageLicensesAsync = ref.watch(packageLicensesProvider);

    const String appLicenseText =
        'MIT License\n\n'
        'Copyright (c) 2026 Tandang Pangestu\n\n'
        'Permission is hereby granted, free of charge, to any person obtaining a copy '
        'of this software and associated documentation files (the "Software"), to deal '
        'in the Software without restriction, including without limitation the rights '
        'to use, copy, modify, merge, publish, distribute, sublicense, and/or sell '
        'copies of the Software, and to permit persons to whom the Software is '
        'furnished to do so, subject to the following conditions:\n\n'
        'The above copyright notice and this permission notice shall be included in all '
        'copies or substantial portions of the Software.\n\n'
        'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR '
        'IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, '
        'FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE '
        'AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER '
        'LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, '
        'OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE '
        'SOFTWARE.';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FrostedGlass(
        backgroundColor: uiState.adaptiveBg
            ? theme.colorScheme.surface.withValues(alpha: uiState.adaptiveBgThemeOverlay)
            : theme.colorScheme.surface,
        blurSigma: uiState.adaptiveBgPanelBlur,
        child: packageLicensesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load licenses: $e')),
          data: (packageLicenses) {
            // Sort the packages alphabetically
            final packageNames = packageLicenses.keys.toList()..sort();

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: packageNames.length,
              itemBuilder: (context, index) {
                final packageName = packageNames[index];
                final licenses = packageLicenses[packageName]!;

                if (index == 0) {
                  return Column(
                    children: [
                      Text(
                        uiState.appName.toPascalCase(),
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(uiState.version, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      Text(appLicenseText, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
                      const SizedBox(height: 48),
                      Divider(color: theme.colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                    ],
                  );
                }

                return ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  title: Text(packageName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${licenses.length} license${licenses.length > 1 ? 's' : ''}.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                  ),
                  children: licenses.map((license) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 24.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          license.paragraphs.map((p) => p.text).join('\n\n'),
                          style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
