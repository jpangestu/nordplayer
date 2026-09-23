import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/core/utils/string_extension.dart';
import 'package:nordplayer/features/settings/about/about_viewmodel.dart';
import 'package:nordplayer/routes/router.dart';
import 'package:nordplayer/widgets/sections/section_container.dart';
import 'package:nordplayer/widgets/sections/section_divider.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutView extends ConsumerWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uiState = ref.watch(aboutViewModelProvider);

    return Scaffold(
      backgroundColor: uiState.adaptiveBg ? Colors.transparent : theme.colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          SectionContainer(
            child: Column(
              children: [
                // Force the Wrap to take up the full width so spaceBetween works
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
                    child: Wrap(
                      alignment: .spaceBetween,
                      crossAxisAlignment: .center,
                      runSpacing: 8.0,
                      children: [
                        Row(
                          mainAxisSize: .min,
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

                            if (uiState.packageInfo != null)
                              Column(
                                crossAxisAlignment: .start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    uiState.appName.toPascalCase(),
                                    style: theme.textTheme.titleLarge!.copyWith(color: theme.colorScheme.onSurface),
                                  ),
                                  Text(
                                    uiState.version,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),

                        Wrap(
                          spacing: 8.0,
                          runSpacing: 12.0,
                          crossAxisAlignment: .center,
                          children: [
                            Padding(
                              padding: const .only(left: 12.0),
                              child: FilledButton.tonalIcon(
                                onPressed: () async {
                                  final Uri url = Uri.parse('https://github.com/jpangestu/nordplayer');

                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(content: Text('Could not open GitHub link.')));
                                    }
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.only(left: 8, right: 10.0, top: 16.0, bottom: 16.0),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                  backgroundColor: theme.colorScheme.primary,
                                ),
                                icon: SvgPicture.asset(
                                  'assets/icons/github_logo.svg',
                                  width: 24,
                                  height: 24,
                                  colorFilter: ColorFilter.mode(theme.colorScheme.onPrimary, BlendMode.srcIn),
                                ),
                                label: Text(
                                  'See Project on GitHub',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),

                            Padding(
                              padding: const .only(left: 12.0),
                              child: FilledButton.tonalIcon(
                                onPressed: () async {
                                  final Uri url = Uri.parse('https://discord.gg/RH5j8H2Y');

                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(content: Text('Could not open Discord link.')));
                                    }
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.only(left: 8, right: 10.0, top: 16.0, bottom: 16.0),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                  backgroundColor: theme.colorScheme.primary,
                                ),
                                icon: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: SvgPicture.asset(
                                    'assets/icons/discord_logo.svg',
                                    width: 15,
                                    height: 15,
                                    colorFilter: ColorFilter.mode(theme.colorScheme.onPrimary, BlendMode.srcIn),
                                  ),
                                ),
                                label: Text(
                                  'Join the Community',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
