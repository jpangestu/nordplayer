import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nordplayer/services/navigation_history.dart';

void main() {
  testWidgets('NavigationHistory routing flow widget test with mock router', (WidgetTester tester) async {
    // 1. Create a dummy router with lightweight routes (no external page widget or database dependencies)
    final dummyRouter = GoRouter(
      initialLocation: '/library',
      routes: [
        GoRoute(path: '/library', builder: (context, state) => const SizedBox.shrink()),
        GoRoute(path: '/tracks', builder: (context, state) => const SizedBox.shrink()),
        GoRoute(path: '/albums', builder: (context, state) => const SizedBox.shrink()),
        GoRoute(path: '/settings/appearance', builder: (context, state) => const SizedBox.shrink()),
      ],
    );

    // 2. Pump the MaterialApp.router overriding the goRouterProvider
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          goRouterProvider.overrideWithValue(dummyRouter),
        ],
        child: MaterialApp.router(
          routerConfig: dummyRouter,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(MaterialApp));
    final container = ProviderScope.containerOf(element);

    // Initial state (should start at /library)
    var state = container.read(navigationHistoryProvider);
    expect(state.history, ['/library']);
    expect(state.currentIndex, 0);
    expect(state.canGoBack, false);
    expect(state.canGoForward, false);

    // 3. Navigate to /tracks
    dummyRouter.go('/tracks');
    await tester.pumpAndSettle();

    state = container.read(navigationHistoryProvider);
    expect(state.history, ['/library', '/tracks']);
    expect(state.currentIndex, 1);
    expect(state.canGoBack, true);
    expect(state.canGoForward, false);

    // 4. Navigate to /albums
    dummyRouter.go('/albums');
    await tester.pumpAndSettle();

    state = container.read(navigationHistoryProvider);
    expect(state.history, ['/library', '/tracks', '/albums']);
    expect(state.currentIndex, 2);

    // 5. Test goBack()
    container.read(navigationHistoryProvider.notifier).goBack();
    await tester.pumpAndSettle();

    state = container.read(navigationHistoryProvider);
    expect(state.currentIndex, 1); // Back at /tracks
    expect(state.canGoForward, true);

    // 6. Test goForward()
    container.read(navigationHistoryProvider.notifier).goForward();
    await tester.pumpAndSettle();

    state = container.read(navigationHistoryProvider);
    expect(state.currentIndex, 2); // Forward at /albums

    // 7. Go back and then start a new navigation to test clearing forward history
    container.read(navigationHistoryProvider.notifier).goBack();
    await tester.pumpAndSettle();

    dummyRouter.go('/settings/appearance');
    await tester.pumpAndSettle();

    state = container.read(navigationHistoryProvider);
    // Forward history /albums should be cleared, replaced by /settings/appearance
    expect(state.history, ['/library', '/tracks', '/settings/appearance']);
    expect(state.currentIndex, 2);
    expect(state.canGoForward, false);
  });
}
