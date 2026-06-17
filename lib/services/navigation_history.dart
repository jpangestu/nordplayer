import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/routes/router.dart';

@immutable
class NavigationHistoryState {
  final List<String> history;
  final int currentIndex;

  const NavigationHistoryState({required this.history, required this.currentIndex});

  bool get canGoBack => currentIndex > 0;
  bool get canGoForward => currentIndex < history.length - 1;

  NavigationHistoryState copyWith({List<String>? history, int? currentIndex}) {
    return NavigationHistoryState(history: history ?? this.history, currentIndex: currentIndex ?? this.currentIndex);
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return router;
});

final navigationHistoryProvider = NotifierProvider<NavigationHistory, NavigationHistoryState>(() {
  return NavigationHistory();
});

class NavigationHistory extends Notifier<NavigationHistoryState> {
  @override
  NavigationHistoryState build() {
    final router = ref.watch(goRouterProvider);

    // Listen to GoRouter's route changes and dispose when provider is disposed
    router.routerDelegate.addListener(_onRouteChanged);
    ref.onDispose(() {
      router.routerDelegate.removeListener(_onRouteChanged);
    });

    final initialLocation = router.routerDelegate.currentConfiguration.uri.toString();
    return NavigationHistoryState(
      history: [initialLocation.isNotEmpty ? initialLocation : '/library'],
      currentIndex: 0,
    );
  }

  void _onRouteChanged() {
    final router = ref.read(goRouterProvider);
    final newLocation = router.routerDelegate.currentConfiguration.uri.toString();
    if (newLocation.isEmpty) return;

    final history = state.history;
    final currentIndex = state.currentIndex;

    // If the location matches the expected current history item, it's a history navigation (or no-op).
    if (currentIndex >= 0 && currentIndex < history.length && history[currentIndex] == newLocation) {
      return;
    }

    // Standard navigation: clear forward history, add new location.
    final newHistory = List<String>.from(history);
    if (currentIndex < newHistory.length - 1) {
      newHistory.removeRange(currentIndex + 1, newHistory.length);
    }

    newHistory.add(newLocation);
    state = NavigationHistoryState(history: newHistory, currentIndex: newHistory.length - 1);
  }

  void goBack() {
    if (!state.canGoBack) return;
    final targetIndex = state.currentIndex - 1;
    final target = state.history[targetIndex];
    state = state.copyWith(currentIndex: targetIndex);
    ref.read(goRouterProvider).go(target);
  }

  void goForward() {
    if (!state.canGoForward) return;
    final targetIndex = state.currentIndex + 1;
    final target = state.history[targetIndex];
    state = state.copyWith(currentIndex: targetIndex);
    ref.read(goRouterProvider).go(target);
  }
}
