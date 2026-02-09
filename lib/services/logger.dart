import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final Logger _globalLogger = Logger(
  printer: PrettyPrinter(
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart
  ),
  level: kReleaseMode ? Level.warning : Level.debug,
);

mixin LoggerMixin {
  Logger get log => _globalLogger;
}
