import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerformanceTracker extends ChangeNotifier {
  static final PerformanceTracker instance = PerformanceTracker._();
  PerformanceTracker._() {
    _loadVisibilitySettings();
    _start();
  }

  static const int _cpuRamUpdateMs = kDebugMode ? 500 : 1000;
  static const int _uiNotifyLimitMs = kDebugMode ? 200 : 500;

  final List<DateTime> _frameTimes = [];
  final List<double> _recentFrameTimes = [];
  int _fps = 0;
  bool _isIdle = true;
  Timer? _timer;
  DateTime _lastFrameTime = DateTime.now();
  DateTime _lastNotificationTime = DateTime.fromMillisecondsSinceEpoch(0);

  final Map<String, bool> _visibility = {
    'simulatedFps': false,
    'avgSimulatedFps': false,
    'minSimulatedFps': false,
    'maxSimulatedFps': false,
    'frameLatency': false,
    'minFrameTime': false,
    'maxFrameTime': false,
    'cpuUsage': false,
    'ramUsage': false,
    'actualFps': false,
  };

  bool isVisible(String key) => _visibility[key] ?? false;

  void _loadVisibilitySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in _visibility.keys) {
        final val = prefs.getBool('perf_visibility_$key');
        if (val != null) {
          _visibility[key] = val;
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  void toggleVisibility(String key) async {
    final current = _visibility[key] ?? false;
    _visibility[key] = !current;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('perf_vis_$key', !current);
    } catch (_) {}
  }

  // Performance metrics
  double _currentFrameTime = 0.0;
  double _minFrameTime = 0.0;
  double _maxFrameTime = 0.0;
  double _currentUiTime = 0.0;
  double _currentGpuTime = 0.0;
  double _cpuUsage = 0.0;
  int _ramBytes = 0;

  int get fps => _fps;
  bool get isIdle => _isIdle;
  double get currentFrameTime => _currentFrameTime;
  double get minFrameTime => _minFrameTime;
  double get maxFrameTime => _maxFrameTime;
  double get currentUiTime => _currentUiTime;
  double get currentGpuTime => _currentGpuTime;
  double get cpuUsage => _cpuUsage;
  int get ramBytes => _ramBytes;

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

  int get simulatedFps {
    if (_isIdle || _currentFrameTime == 0.0) return 0;
    return (1000.0 / _currentFrameTime).round();
  }

  int get minSimulatedFps {
    if (_maxFrameTime == 0.0) return 0;
    return (1000.0 / _maxFrameTime).round();
  }

  int get maxSimulatedFps {
    if (_minFrameTime == 0.0) return 0;
    return (1000.0 / _minFrameTime).round();
  }

  double get averageFrameTime {
    if (_recentFrameTimes.isEmpty) return 0.0;
    final sum = _recentFrameTimes.reduce((a, b) => a + b);
    return sum / _recentFrameTimes.length;
  }

  int get averageSimulatedFps {
    final avg = averageFrameTime;
    if (_isIdle || avg == 0.0) return 0;
    return (1000.0 / avg).round();
  }

  void resetStats() {
    _minFrameTime = 0.0;
    _maxFrameTime = 0.0;
    _recentFrameTimes.clear();
    notifyListeners();
  }

  void _start() {
    // Listen to exact frame timings from Flutter Engine
    SchedulerBinding.instance.addTimingsCallback(_onReportTimings);

    _timer = Timer.periodic(const Duration(milliseconds: _cpuRamUpdateMs), (timer) {
      final now = DateTime.now();
      _frameTimes.removeWhere((t) => now.difference(t).inMilliseconds > 1000);

      // Memory & CPU update
      _ramBytes = ProcessInfo.currentRss;
      if (Platform.isWindows) {
        _cpuUsage = WinCpu.instance.getCpuUsage();
      } else if (Platform.isLinux) {
        _cpuUsage = LinuxCpu.instance.getCpuUsage();
      } else {
        _cpuUsage = 0.0;
      }

      // If the last frame was more than 1.5 seconds ago, mark as idle
      if (now.difference(_lastFrameTime).inMilliseconds > 1500) {
        if (!_isIdle) {
          _isIdle = true;
          _fps = 0;
          _currentFrameTime = 0.0;
          _currentUiTime = 0.0;
          _currentGpuTime = 0.0;
          notifyListeners();
        }
      } else {
        _isIdle = false;
        _fps = _frameTimes.length;
        notifyListeners();
      }
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

    // Rate-limit UI rebuild notifications based on build mode
    if (now.difference(_lastNotificationTime).inMilliseconds > _uiNotifyLimitMs) {
      notifyListeners();
      _lastNotificationTime = now;
    }
  }

  void disposeTracker() {
    _timer?.cancel();
    SchedulerBinding.instance.removeTimingsCallback(_onReportTimings);
    WinCpu.instance.dispose();
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
  static final WinCpu instance = WinCpu._();
  WinCpu._() {
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
    if (_creationTimePtr != null) _localFree!(_creationTimePtr!);
    if (_exitTimePtr != null) _localFree!(_exitTimePtr!);
    if (_kernelTimePtr != null) _localFree!(_kernelTimePtr!);
    if (_userTimePtr != null) _localFree!(_userTimePtr!);
  }
}

// ======================================= Linux CPU Helper =======================================

class LinuxCpu {
  static final LinuxCpu instance = LinuxCpu._();
  LinuxCpu._() {
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
