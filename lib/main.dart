import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:maruti_kirba_lighting_solutions/auth_redirect.dart';
import 'package:maruti_kirba_lighting_solutions/authentication/auth_provider.dart';
import 'package:maruti_kirba_lighting_solutions/authentication/auth_service.dart';
import 'package:maruti_kirba_lighting_solutions/firebase_options.dart';
import 'package:maruti_kirba_lighting_solutions/pages/admin_dashboard.dart';
import 'package:maruti_kirba_lighting_solutions/pages/login-pages/admin_login.dart';
import 'package:maruti_kirba_lighting_solutions/pages/login-pages/executive_login.dart';
import 'package:maruti_kirba_lighting_solutions/pages/orders/order_master.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
  ]);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: const MarutiKirbaApp(),
    ),
  );
}

final _router = GoRouter(
  redirect: (BuildContext context, GoRouterState state) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isLoading) {
      return null;
    }

    final isLoggedIn = authProvider.isAuthenticated;
    final isAdmin = authProvider.isAdmin;
    final isLoginRoute =
        state.matchedLocation == '/admin_login' ||
        state.matchedLocation == '/executive_login';

    // If not logged in and trying to access protected route
    if (!isLoggedIn && !isLoginRoute && state.matchedLocation != '/') {
      return '/';
    }

    // If logged in and trying to access login page
    if (isLoggedIn && isLoginRoute) {
      return isAdmin ? '/admin_dashboard' : '/order_master';
    }

    // check order master access
    if (state.matchedLocation == '/order_master' &&
        !authProvider.canAccessOrderMaster) {
      return '/admin_dashboard';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthRedirect(),
      routes: [
        GoRoute(
          path: 'admin_login',
          builder: (context, state) => const AdminLogin(),
        ),
        GoRoute(
          path: 'executive_login',
          builder: (context, state) => const ExecutiveLogin(),
        ),
        GoRoute(
          path: 'admin_dashboard',
          builder: (context, state) => AdminDashboard(
            authService: Provider.of<AuthService>(context, listen: false),
          ),
        ),
        GoRoute(
          path: 'order_master',
          builder: (context, state) => OrderMaster(
            authService: Provider.of<AuthService>(context, listen: false),
          ),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Error: ${state.error}'))),
);

class MarutiKirbaApp extends StatelessWidget {
  const MarutiKirbaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Maruti Kirba Lights',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            fontFamily: 'Aptos Display',
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Aptos Display',
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}
