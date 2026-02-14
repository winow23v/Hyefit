import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/user/login_screen.dart';
import 'screens/user/signup_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/card/card_list_screen.dart';
import 'screens/card/card_detail_screen.dart';
import 'screens/transaction/transaction_add_screen.dart';
import 'screens/admin/admin_card_list_screen.dart';
import 'screens/admin/admin_card_add_screen.dart';
import 'screens/admin/admin_benefit_tiers_screen.dart';
import 'screens/admin/admin_card_web_import_screen.dart';
import 'screens/mypage/mypage_screen.dart';
import 'components/hyefit_bottom_nav.dart';

// 현재 탭 인덱스 관리
final _currentTabProvider = StateProvider<int>((ref) => 0);

// GoRouter 설정
final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);
  final isAdmin = ref.watch(isAdminProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/user/login' ||
          state.matchedLocation == '/user/signup';
      final inAdminPage = state.matchedLocation.startsWith('/admin');

      if (!isLoggedIn && !loggingIn) return '/user/login';
      if (inAdminPage && !isAdmin) return '/home';
      if (isLoggedIn && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),
      GoRoute(
        path: '/user/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/user/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return _MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/card',
            builder: (context, state) => const CardListScreen(),
          ),
          GoRoute(
            path: '/card/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CardDetailScreen(userCardId: id);
            },
          ),
          GoRoute(
            path: '/transaction/add',
            builder: (context, state) => const TransactionAddScreen(),
          ),
          GoRoute(
            path: '/mypage',
            builder: (context, state) => const MyPageScreen(),
          ),
          GoRoute(
            path: '/admin/cards',
            builder: (context, state) => const AdminCardListScreen(),
          ),
          GoRoute(
            path: '/admin/cards/add',
            builder: (context, state) => const AdminCardAddScreen(),
          ),
          GoRoute(
            path: '/admin/cards/web-import',
            builder: (context, state) => const AdminCardWebImportScreen(),
          ),
          GoRoute(
            path: '/admin/cards/:id/tiers',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AdminBenefitTiersScreen(cardId: id);
            },
          ),
        ],
      ),
    ],
  );
});

class HyeFitApp extends ConsumerWidget {
  final String? startupError;

  const HyeFitApp({super.key, this.startupError});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (startupError != null) {
      return MaterialApp(
        title: '혜핏',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text('앱 초기화 실패'),
                  const SizedBox(height: 8),
                  Text(
                    startupError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final authBootstrap = ref.watch(authBootstrapProvider);

    if (authBootstrap.isLoading) {
      return MaterialApp(
        title: '혜핏',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '혜핏',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}

class _MainShell extends ConsumerWidget {
  final Widget child;

  const _MainShell({required this.child});

  int _getTabIndexFromLocation(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/card')) return 1;
    if (location.startsWith('/transaction')) return 2;
    if (location.startsWith('/mypage')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final currentTab = _getTabIndexFromLocation(currentLocation);

    // 현재 위치 기반으로 탭 인덱스 동기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(_currentTabProvider) != currentTab) {
        ref.read(_currentTabProvider.notifier).state = currentTab;
      }
    });

    return Scaffold(
      body: child,
      bottomNavigationBar: HyefitBottomNav(
        currentIndex: currentTab,
        onTap: (index) {
          // 같은 탭 클릭 시 무시
          if (index == currentTab) return;

          ref.read(_currentTabProvider.notifier).state = index;
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/card');
              break;
            case 2:
              context.go('/transaction/add');
              break;
            case 3:
              context.go('/mypage');
              break;
          }
        },
      ),
    );
  }
}
