import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
export 'package:logger/logger.dart' show Logger;

final Logger _globalLogger = Logger(
  printer: PrettyPrinter(
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart
  ),
  level: kReleaseMode ? Level.warning : Level.debug,
);

mixin LoggerMixin {
  Logger get log => _globalLogger;
}
