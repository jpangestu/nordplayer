import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nordplayer/data/services/system/preference_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final performanceTrackerProvider = NotifierProvider<PerformanceTracker, PerformanceState>(() {
  return PerformanceTracker();
});

@immutable
class const PerformanceState({
  final int actualFrameRate = 0,
  final bool isIdle = true,
  final double currentFrameTime = 0.0,
  final double minFrameTime = 0.0,
  final double maxFrameTime = 0.0,
  final double averageFrameTime = 0.0,
  final double currentUiTime = 0.0,
  final double currentGpuTime = 0.0,
  final double cpuUsage = 0.0,
  final int ramBytes = 0,
  final Map<String, bool> visibility = const {
    'potentialFps': false,
    'avgPotentialFps': false,
    'minPotentialFps': false,
    'maxPotentialFps': false,
    'frameLatency': false,
    'averageFrameTime': false,
    'minFrameTime': false,
    'maxFrameTime': false,
    'actualFrameRate': false,
    'cpuUsage': false,
    'ramUsage': false,
  },
}) {

  bool isVisible(String key) => visibility[key] ?? false;

  String formatRam(int bytes) {
    final mb = bytes / (1024.0 * 1024.0);
    if (mb >= 1024.0) {
      final gb = mb / 1024.0;
      return '${gb.toStringAsFixed(1)} GB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  String formatLatency(double ms) {
    if (ms >= 1000.0) {
      final sec = ms / 1000.0;
      return '${sec.toStringAsFixed(1)} s';
    }
    return '${ms.toStringAsFixed(1)} ms';
  }

  int get potentialFps {
    if (isIdle || currentFrameTime == 0.0) return 0;
    return (1000.0 / currentFrameTime).round();
  }

  int get minPotentialFps {
    if (maxFrameTime == 0.0) return 0;
    return (1000.0 / maxFrameTime).round();
  }

  int get maxPotentialFps {
    if (minFrameTime == 0.0) return 0;
    return (1000.0 / minFrameTime).round();
  }

  int get averagePotentialFps {
    if (isIdle || averageFrameTime == 0.0) return 0;
    return (1000.0 / averageFrameTime).round();
  }

  PerformanceState copyWith({
    int? actualFrameRate,
    bool? isIdle,
    double? currentFrameTime,
    double? minFrameTime,
    double? maxFrameTime,
    double? averageFrameTime,
    double? currentUiTime,
    double? currentGpuTime,
    double? cpuUsage,
    int? ramBytes,
    Map<String, bool>? visibility,
  }) {
    return PerformanceState(
      actualFrameRate: actualFrameRate ?? this.actualFrameRate,
      isIdle: isIdle ?? this.isIdle,
      currentFrameTime: currentFrameTime ?? this.currentFrameTime,
      minFrameTime: minFrameTime ?? this.minFrameTime,
      maxFrameTime: maxFrameTime ?? this.maxFrameTime,
      averageFrameTime: averageFrameTime ?? this.averageFrameTime,
      currentUiTime: currentUiTime ?? this.currentUiTime,
      currentGpuTime: currentGpuTime ?? this.currentGpuTime,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      ramBytes: ramBytes ?? this.ramBytes,
      visibility: visibility ?? this.visibility,
    );
  }
}

class PerformanceTracker extends Notifier<PerformanceState> {
  static const Set<String> prefKeys = PrefConstants.performanceKeys;

  static const int _cpuRamUpdateMs = kDebugMode ? 500 : 1000;
  static const int _uiNotifyLimitMs = kDebugMode ? 200 : 500;

  late SharedPreferencesWithCache _prefs;
  WinCpu? _winCpu;
  LinuxCpu? _linuxCpu;

  final List<DateTime> _frameTimes = [];
  final List<double> _recentFrameTimes = [];
  int _actualFrameRate = 0;
  bool _isIdle = true;
  Timer? _timer;
  DateTime _lastFrameTime = DateTime.now();
  DateTime _lastNotificationTime = DateTime.fromMillisecondsSinceEpoch(0);

  double _currentFrameTime = 0.0;
  double _minFrameTime = 0.0;
  double _maxFrameTime = 0.0;
  double _currentUiTime = 0.0;
  double _currentGpuTime = 0.0;
  double _cpuUsage = 0.0;
  int _ramBytes = 0;

  @override
  PerformanceState build() {
    _prefs = ref.watch(sharedPrefsProvider);

    if (Platform.isWindows) {
      _winCpu = WinCpu();
    } else if (Platform.isLinux) {
      _linuxCpu = LinuxCpu();
    }

    final initialVisibility = _loadVisibilitySettings();

    _start();

    ref.onDispose(() {
      _timer?.cancel();
      SchedulerBinding.instance.removeTimingsCallback(_onReportTimings);
      _winCpu?.dispose();
    });

    return PerformanceState(visibility: initialVisibility);
  }

  Map<String, bool> _loadVisibilitySettings() {
    final visibility = <String, bool>{
      'potentialFps': false,
      'avgPotentialFps': false,
      'minPotentialFps': false,
      'maxPotentialFps': false,
      'frameLatency': false,
      'averageFrameTime': false,
      'minFrameTime': false,
      'maxFrameTime': false,
      'actualFrameRate': false,
      'cpuUsage': false,
      'ramUsage': false,
    };

    for (final key in visibility.keys) {
      final val = _prefs.getBool('perf_vis_$key');
      if (val != null) {
        visibility[key] = val;
      }
    }
    return visibility;
  }

  void toggleVisibility(String key) {
    final current = state.visibility[key] ?? false;
    final next = !current;
    final updatedVisibility = Map<String, bool>.from(state.visibility);
    updatedVisibility[key] = next;
    state = state.copyWith(visibility: updatedVisibility);
    _prefs.setBool('perf_vis_$key', next);
  }

  void resetStats() {
    _minFrameTime = 0.0;
    _maxFrameTime = 0.0;
    _recentFrameTimes.clear();
    state = state.copyWith(
      minFrameTime: 0.0,
      maxFrameTime: 0.0,
      averageFrameTime: 0.0,
    );
  }

  void _start() {
    SchedulerBinding.instance.addTimingsCallback(_onReportTimings);

    _timer = Timer.periodic(const Duration(milliseconds: _cpuRamUpdateMs), (timer) {
      final now = DateTime.now();
      _frameTimes.removeWhere((t) => now.difference(t).inMilliseconds > 1000);

      // Memory & CPU update
      _ramBytes = ProcessInfo.currentRss;
      if (Platform.isWindows) {
        _cpuUsage = _winCpu?.getCpuUsage() ?? 0.0;
      } else if (Platform.isLinux) {
        _cpuUsage = _linuxCpu?.getCpuUsage() ?? 0.0;
      } else {
        _cpuUsage = 0.0;
      }

      // If the last frame was more than 1.5 seconds ago, mark as idle
      if (now.difference(_lastFrameTime).inMilliseconds > 1500) {
        _isIdle = true;
        _actualFrameRate = 0;
        _currentFrameTime = 0.0;
        _currentUiTime = 0.0;
        _currentGpuTime = 0.0;
      } else {
        _isIdle = false;
        _actualFrameRate = _frameTimes.length;
      }

      _notifyState(now);
    });
  }

  void _onReportTimings(List<FrameTiming> timings) {
    if (timings.isEmpty) return;

    final now = DateTime.now();
    _lastFrameTime = now;

    for (final timing in timings) {
      _frameTimes.add(now);

      final buildMs = timing.buildDuration.inMicroseconds / 1000.0;
      final rasterMs = timing.rasterDuration.inMicroseconds / 1000.0;
      final totalMs = timing.totalSpan.inMicroseconds / 1000.0;

      _currentFrameTime = totalMs;
      _currentUiTime = buildMs;
      _currentGpuTime = rasterMs;

      if (_currentFrameTime > 0.0) {
        _recentFrameTimes.add(_currentFrameTime);
        if (_recentFrameTimes.length > 100) {
          _recentFrameTimes.removeAt(0);
        }
        if (_minFrameTime == 0.0 || _currentFrameTime < _minFrameTime) {
          _minFrameTime = _currentFrameTime;
        }
        if (_currentFrameTime > _maxFrameTime) {
          _maxFrameTime = _currentFrameTime;
        }
      }
    }

    if (now.difference(_lastNotificationTime).inMilliseconds > _uiNotifyLimitMs) {
      _notifyState(now);
    }
  }

  void _notifyState(DateTime now) {
    _lastNotificationTime = now;
    final avgFrameTime = _recentFrameTimes.isEmpty
        ? 0.0
        : _recentFrameTimes.reduce((a, b) => a + b) / _recentFrameTimes.length;

    state = state.copyWith(
      actualFrameRate: _actualFrameRate,
      isIdle: _isIdle,
      currentFrameTime: _currentFrameTime,
      minFrameTime: _minFrameTime,
      maxFrameTime: _maxFrameTime,
      averageFrameTime: avgFrameTime,
      currentUiTime: _currentUiTime,
      currentGpuTime: _currentGpuTime,
      cpuUsage: _cpuUsage,
      ramBytes: _ramBytes,
    );
  }
}

// ======================================= Win32 CPU Helper =======================================

typedef GetCurrentProcessNative = IntPtr Function();
typedef GetCurrentProcessDart = int Function();

typedef GetProcessTimesNative =
    Int32 Function(
      IntPtr hProcess,
      Pointer<Uint64> lpCreationTime,
      Pointer<Uint64> lpExitTime,
      Pointer<Uint64> lpKernelTime,
      Pointer<Uint64> lpUserTime,
    );
typedef GetProcessTimesDart =
    int Function(
      int hProcess,
      Pointer<Uint64> lpCreationTime,
      Pointer<Uint64> lpExitTime,
      Pointer<Uint64> lpKernelTime,
      Pointer<Uint64> lpUserTime,
    );

typedef LocalAllocNative = Pointer<Uint64> Function(Uint32 uFlags, IntPtr uBytes);
typedef LocalAllocDart = Pointer<Uint64> Function(int uFlags, int uBytes);

typedef LocalFreeNative = Pointer Function(Pointer hMem);
typedef LocalFreeDart = Pointer Function(Pointer hMem);

class WinCpu {
  WinCpu() {
    _init();
  }

  bool _initialized = false;
  int _currentProcessHandle = 0;

  Pointer<Uint64>? _creationTimePtr;
  Pointer<Uint64>? _exitTimePtr;
  Pointer<Uint64>? _kernelTimePtr;
  Pointer<Uint64>? _userTimePtr;

  GetProcessTimesDart? _getProcessTimes;
  LocalFreeDart? _localFree;

  int _lastCpuTimeUs = 0;
  int _lastTimeUs = 0;
  double _lastCpuUsage = 0.0;

  void _init() {
    if (!Platform.isWindows) return;
    try {
      final kernel32 = DynamicLibrary.open('kernel32.dll');

      final getCurrentProcess = kernel32.lookupFunction<GetCurrentProcessNative, GetCurrentProcessDart>(
        'GetCurrentProcess',
      );
      _getProcessTimes = kernel32.lookupFunction<GetProcessTimesNative, GetProcessTimesDart>('GetProcessTimes');
      final localAlloc = kernel32.lookupFunction<LocalAllocNative, LocalAllocDart>('LocalAlloc');
      _localFree = kernel32.lookupFunction<LocalFreeNative, LocalFreeDart>('LocalFree');

      _currentProcessHandle = getCurrentProcess();

      // LMEM_ZEROINIT = 0x0040, allocate 8 bytes for 64-bit int
      _creationTimePtr = localAlloc(0x0040, 8);
      _exitTimePtr = localAlloc(0x0040, 8);
      _kernelTimePtr = localAlloc(0x0040, 8);
      _userTimePtr = localAlloc(0x0040, 8);

      _initialized = true;

      _lastTimeUs = DateTime.now().microsecondsSinceEpoch;
      _lastCpuTimeUs = _getCurrentCpuTimeUs();
    } catch (e) {
      _initialized = false;
    }
  }

  int _getCurrentCpuTimeUs() {
    if (!_initialized ||
        _creationTimePtr == null ||
        _exitTimePtr == null ||
        _kernelTimePtr == null ||
        _userTimePtr == null) {
      return 0;
    }
    final result = _getProcessTimes!(
      _currentProcessHandle,
      _creationTimePtr!,
      _exitTimePtr!,
      _kernelTimePtr!,
      _userTimePtr!,
    );
    if (result == 0) return 0;

    final kernelTimeVal = _kernelTimePtr!.value;
    final userTimeVal = _userTimePtr!.value;
    // 100-nanosecond units to microseconds: divide by 10
    return (kernelTimeVal + userTimeVal) ~/ 10;
  }

  double getCpuUsage() {
    if (!Platform.isWindows || !_initialized) return 0.0;

    final currentTimeUs = DateTime.now().microsecondsSinceEpoch;
    final currentCpuTimeUs = _getCurrentCpuTimeUs();

    final deltaCpuTimeUs = currentCpuTimeUs - _lastCpuTimeUs;
    final deltaTimeUs = currentTimeUs - _lastTimeUs;

    double cpuUsage = 0.0;
    if (deltaTimeUs > 100000) {
      // Update at most every 100ms
      cpuUsage = (deltaCpuTimeUs / (deltaTimeUs * Platform.numberOfProcessors)) * 100.0;
      _lastCpuTimeUs = currentCpuTimeUs;
      _lastTimeUs = currentTimeUs;
      _lastCpuUsage = cpuUsage.clamp(0.0, 100.0);
    }

    return _lastCpuUsage;
  }

  void dispose() {
    if (_creationTimePtr != null) {
      _localFree!(_creationTimePtr!);
      _creationTimePtr = null;
    }
    if (_exitTimePtr != null) {
      _localFree!(_exitTimePtr!);
      _exitTimePtr = null;
    }
    if (_kernelTimePtr != null) {
      _localFree!(_kernelTimePtr!);
      _kernelTimePtr = null;
    }
    if (_userTimePtr != null) {
      _localFree!(_userTimePtr!);
      _userTimePtr = null;
    }
    _initialized = false;
  }
}

// ======================================= Linux CPU Helper =======================================

class LinuxCpu {
  LinuxCpu() {
    _init();
  }

  bool _initialized = false;
  int _lastCpuTicks = 0;
  int _lastTimeUs = 0;
  double _lastCpuUsage = 0.0;

  void _init() {
    if (!Platform.isLinux) return;
    try {
      final statFile = File('/proc/self/stat');
      if (statFile.existsSync()) {
        _initialized = true;
        _lastTimeUs = DateTime.now().microsecondsSinceEpoch;
        _lastCpuTicks = _getCurrentCpuTicks();
      }
    } catch (_) {
      _initialized = false;
    }
  }

  int _getCurrentCpuTicks() {
    if (!_initialized) return 0;
    try {
      final contents = File('/proc/self/stat').readAsStringSync();
      final lastParen = contents.lastIndexOf(')');
      if (lastParen != -1) {
        final postParen = contents.substring(lastParen + 1).trim();
        final tokens = postParen.split(RegExp(r'\s+'));
        if (tokens.length > 12) {
          final utime = int.parse(tokens[11]);
          final stime = int.parse(tokens[12]);
          return utime + stime;
        }
      }
    } catch (_) {
      // ignore
    }
    return 0;
  }

  double getCpuUsage() {
    if (!Platform.isLinux || !_initialized) return 0.0;

    final currentTimeUs = DateTime.now().microsecondsSinceEpoch;
    final currentCpuTicks = _getCurrentCpuTicks();

    final deltaCpuTicks = currentCpuTicks - _lastCpuTicks;
    final deltaTimeUs = currentTimeUs - _lastTimeUs;

    double cpuUsage = 0.0;
    if (deltaTimeUs > 100000) {
      // Update at most every 100ms
      cpuUsage = (deltaCpuTicks * 1000000.0) / (deltaTimeUs * Platform.numberOfProcessors);
      _lastCpuTicks = currentCpuTicks;
      _lastTimeUs = currentTimeUs;
      _lastCpuUsage = cpuUsage.clamp(0.0, 100.0);
    }

    return _lastCpuUsage;
  }
}
