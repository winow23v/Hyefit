import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/cards/card_list_screen.dart';
import 'screens/cards/card_detail_screen.dart';
import 'screens/transactions/transaction_add_screen.dart';
import 'screens/admin/admin_card_list_screen.dart';
import 'screens/admin/admin_card_add_screen.dart';
import 'screens/admin/admin_benefit_rules_screen.dart';
import 'widgets/hyefit_bottom_nav.dart';

// 현재 탭 인덱스 관리
final _currentTabProvider = StateProvider<int>((ref) => 0);

// GoRouter 설정
final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (!isLoggedIn && !loggingIn) return '/login';
      if (isLoggedIn && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return _MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/cards',
            builder: (context, state) => const CardListScreen(),
          ),
          GoRoute(
            path: '/cards/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CardDetailScreen(userCardId: id);
            },
          ),
          GoRoute(
            path: '/add',
            builder: (context, state) => const TransactionAddScreen(),
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
            path: '/admin/cards/:id/rules',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AdminBenefitRulesScreen(cardId: id);
            },
          ),
        ],
      ),
    ],
  );
});

class HyeFitApp extends ConsumerWidget {
  const HyeFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(_currentTabProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: HyefitBottomNav(
        currentIndex: currentTab,
        onTap: (index) {
          ref.read(_currentTabProvider.notifier).state = index;
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/cards');
              break;
            case 2:
              context.go('/add');
              break;
          }
        },
      ),
    );
  }
}
