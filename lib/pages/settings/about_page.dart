import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/utils/string_extension.dart';
import 'package:nordplayer/widgets/settings/section_card.dart';
import 'package:nordplayer/widgets/settings/section_divider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;

    return Scaffold(
      backgroundColor: appConfig.adaptiveBg ? Colors.transparent : theme.colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          SectionCard(
            child: Column(
              children: [
                // 1. Force the Wrap to take up the full width so spaceBetween works
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween, // Pushes Button to the right
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 8.0, // Vertical gap when wrapped
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.0),
                                ),
                                child: SvgPicture.asset('assets/icons/nordplayer_logo.svg', width: 72, height: 72),
                              ),
                            ),

                            if (_packageInfo != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    _packageInfo!.appName.pascalCase,
                                    style: theme.textTheme.titleLarge!.copyWith(color: theme.colorScheme.onSurface),
                                  ),
                                  Text(
                                    "v${_packageInfo!.version}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),

                        Padding(
                          padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
                          child: FilledButton.tonalIcon(
                            onPressed: () async {
                              final Uri url = Uri.parse('https://github.com/jpangestu/nordplayer');

                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(const SnackBar(content: Text('Could not open GitHub link.')));
                                }
                              }
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.only(left: 8, right: 10.0, top: 16.0, bottom: 16.0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                            ),
                            icon: SvgPicture.asset(
                              'assets/icons/github_logo.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(theme.colorScheme.onSurface, BlendMode.srcIn),
                            ),
                            label: Text(
                              'See Project on GitHub',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SectionDivider(),

                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('License'),
                  subtitle: const Text('See all license used by Nordplayer'),
                  trailing: const Icon(Icons.keyboard_arrow_right),
                  onTap: () {
                    context.go('${Routes.aboutPage}/${Routes.licensesPage}');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
