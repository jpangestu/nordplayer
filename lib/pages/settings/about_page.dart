import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/routes/routes.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/utils/string_extensions.dart';
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
      backgroundColor: appConfig.adaptiveBg
          ? Colors.transparent
          : theme.colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          SectionWrapper(
            child: Column(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                            width: 1.0,
                          ),
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/nordplayer_logo_72.svg',
                          width: 72,
                          height: 72,
                        ),
                      ),
                    ),

                    if (_packageInfo != null)
                      Column(
                        crossAxisAlignment: .start,
                        children: [
                          SizedBox(height: 4),
                          Text(
                            _packageInfo!.appName.pascalCase,
                            style: theme.textTheme.titleLarge!.copyWith(
                              color: theme.colorScheme.onSurface,
                              // color: Color(0xFF88C0D0),
                            ),
                          ),
                          Text(
                            "v${_packageInfo!.version}",
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                    Spacer(),

                    FilledButton.tonalIcon(
                      onPressed: () async {
                        final Uri url = Uri.parse(
                          'https://github.com/jpangestu/nordplayer',
                        );

                        // Safely opens the default web browser
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          // Show a Snackbar if the user's OS fails to open the browser
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open GitHub link.'),
                              ),
                            );
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 10.0,
                          top: 16.0,
                          bottom: 16.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      icon: SvgPicture.asset(
                        'assets/icons/github_logo.svg',
                        width: 24,
                        height: 24,
                        // Dynamically colors the SVG to match the text color of the tonal button
                        colorFilter: ColorFilter.mode(
                          theme.colorScheme.onSurface,
                          BlendMode.srcIn,
                        ),
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

                    SizedBox(width: 16),
                  ],
                ),

                SectionDivider(),

                ListTile(
                  leading: Icon(Icons.description_outlined),
                  title: Text('License'),
                  subtitle: Text('See all license used by Nordplayer'),
                  trailing: Icon(Icons.keyboard_arrow_right),
                  onTap: () {
                    context.go(
                      '/settings/${Routes.aboutPage}/${Routes.licensesPage}',
                    );
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
