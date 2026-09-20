import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordplayer/features/settings/about_viewmodel.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AboutViewModel Providers', () {
    test('packageInfoProvider can be read and overridden', () async {
      PackageInfo.setMockInitialValues(
        appName: 'Nordplayer Test',
        packageName: 'com.nordplayer.test',
        version: '1.2.3',
        buildNumber: '45',
        buildSignature: '',
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final info = await container.read(packageInfoProvider.future);
      expect(info.appName, equals('Nordplayer Test'));
      expect(info.version, equals('1.2.3'));
    });

    test('packageLicensesProvider groups licenses by package name', () async {
      LicenseRegistry.addLicense(() => Stream.fromIterable([
            const LicenseEntryWithLineBreaks(
              ['test_pkg_a', 'test_pkg_b'],
              'Sample license text',
            ),
          ]));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final licensesMap = await container.read(packageLicensesProvider.future);
      expect(licensesMap, isA<Map<String, List<LicenseEntry>>>());
      expect(licensesMap.containsKey('test_pkg_a'), isTrue);
      expect(licensesMap.containsKey('test_pkg_b'), isTrue);
      expect(licensesMap['test_pkg_a']!.first.paragraphs.first.text, equals('Sample license text'));
    });
  });
}
