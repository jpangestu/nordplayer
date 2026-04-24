import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/utils/string_extensions.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LicensesPage extends ConsumerStatefulWidget {
  const LicensesPage({super.key});

  @override
  ConsumerState<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends ConsumerState<LicensesPage> {
  final Map<String, List<LicenseEntry>> _packageLicenses = {};
  bool _isLoading = true;
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final info = await PackageInfo.fromPlatform();

    // Fetch all raw licenses from the system
    final licenses = await LicenseRegistry.licenses.toList();

    // Group them by package name
    for (final license in licenses) {
      for (final package in license.packages) {
        _packageLicenses.putIfAbsent(package, () => []).add(license);
      }
    }

    if (mounted) {
      setState(() {
        _packageInfo = info;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;

    // Sort the packages alphabetically
    final packageNames = _packageLicenses.keys.toList()..sort();

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
        backgroundColor: appConfig.adaptiveBg
            ? theme.colorScheme.surface.withValues(alpha: 0.6)
            : theme.colorScheme.surface,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: EdgeInsets.all(24),
                itemCount: packageNames.length,
                itemBuilder: (context, index) {
                  // --- HEADER BLOCK ---
                  if (index == 0) {
                    return Column(
                      children: [
                        Text(
                          _packageInfo?.appName.pascalCase ?? 'Nordplayer',
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(_packageInfo != null ? _packageInfo!.version : '', style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 16),
                        Text(appLicenseText, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
                        const SizedBox(height: 48),
                        Divider(color: theme.colorScheme.outlineVariant),
                        const SizedBox(height: 16),
                      ],
                    );
                  }

                  // --- LIST ITEMS (Subtract 1 from index because of header) ---
                  final packageName = packageNames[index];
                  final licenses = _packageLicenses[packageName]!;

                  return ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    title: Text(packageName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    // Matches the flutter default layout text style
                    subtitle: Text(
                      '${licenses.length} license${licenses.length > 1 ? 's' : ''}.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
              ),
      ),
    );
  }
}
