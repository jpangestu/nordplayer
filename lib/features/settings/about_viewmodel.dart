import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

final packageLicensesProvider = FutureProvider<Map<String, List<LicenseEntry>>>((ref) async {
  final Map<String, List<LicenseEntry>> packageLicenses = {};
  final licenses = await LicenseRegistry.licenses.toList();
  for (final license in licenses) {
    for (final package in license.packages) {
      packageLicenses.putIfAbsent(package, () => []).add(license);
    }
  }
  return packageLicenses;
});
