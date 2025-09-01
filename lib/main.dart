import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:maruti_kirba_lighting_solutions/auth_redirect.dart';
import 'package:maruti_kirba_lighting_solutions/authentication/auth_provider.dart';
import 'package:maruti_kirba_lighting_solutions/authentication/auth_service.dart';
import 'package:maruti_kirba_lighting_solutions/firebase_options.dart';
import 'package:maruti_kirba_lighting_solutions/pages/admin_dashboard.dart';
import 'package:maruti_kirba_lighting_solutions/pages/cda_page.dart';
import 'package:maruti_kirba_lighting_solutions/pages/fetch-pages/display_fetch_pages.dart';
import 'package:maruti_kirba_lighting_solutions/pages/fetch-pages/update_fetch_pages.dart';
import 'package:maruti_kirba_lighting_solutions/pages/import/import_customer.dart';
import 'package:maruti_kirba_lighting_solutions/pages/import/import_item.dart';
import 'package:maruti_kirba_lighting_solutions/pages/import/import_main.dart';
import 'package:maruti_kirba_lighting_solutions/pages/login-pages/admin_login.dart';
import 'package:maruti_kirba_lighting_solutions/pages/login-pages/executive_login.dart';
import 'package:maruti_kirba_lighting_solutions/pages/masters/customer_master.dart';
import 'package:maruti_kirba_lighting_solutions/pages/masters/executive_master.dart';
import 'package:maruti_kirba_lighting_solutions/pages/masters/item_master.dart';
import 'package:maruti_kirba_lighting_solutions/pages/mysql-connection-test/mysql_test.dart';
import 'package:maruti_kirba_lighting_solutions/pages/orders/order_master.dart';
import 'package:maruti_kirba_lighting_solutions/service/mysql_service.dart';
import 'package:provider/provider.dart';

// Helper function to load environment variables
Future<void> _loadEnvVariables() async {
  try {
    await dotenv.load(fileName: "assets/.env");
    // ignore: avoid_print
    print("Environment variables loaded successfully");
  } catch (e) {
    // ignore: avoid_print
    print("Warning: Could not load .env file: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable debug prints in release mode for better performance
  if (const bool.fromEnvironment('dart.vm.product')) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  try {
    // Load environment variables
    await _loadEnvVariables();

    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
      // ignore: body_might_complete_normally_catch_error
    ).catchError((error) {
      // ignore: avoid_print
      print("Firebase initialization error: $error");
    });

    // Create MySQL service but initialize it asynchronously without blocking
    final mysqlService = MysqlService();

    // Initialize MySQL in background without blocking app startup
    // Use unawaited to prevent waiting for completion
    Future.microtask(() async {
      try {
        await mysqlService.initialize();
        // ignore: avoid_print
        print("MySQL initialized successfully in background");
      } catch (error) {
        // ignore: avoid_print
        print("MySQL background initialization error: $error");
      }
    });

    runApp(
      MultiProvider(
        providers: [
          Provider<AuthService>(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (context) => AuthProvider()),
          Provider<MysqlService>(create: (_) => mysqlService),
        ],
        child: const MarutiKirbaApp(),
      ),
    );
  } catch (e) {
    // ignore: avoid_print
    print("Fatal error during initialization: $e");
    // You could show an error screen here
    runApp(const ErrorApp());
  }
}

// Simple error widget in case of initialization failure
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'App Initialization Failed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Please check your internet connection and try again.',
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // You could implement a restart mechanism here
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
        GoRoute(
          path: 'cda_page',
          builder: (context, state) {
            final masterType = state.extra as String;
            return CdaPage(masterType: masterType);
          },
        ),
        GoRoute(
          path: 'display_fetch',
          builder: (context, state) {
            final masterType = state.extra as String;
            return DisplayFetchPage(masterType: masterType);
          },
        ),
        GoRoute(
          path: 'update_fetch',
          builder: (context, state) {
            final masterType = state.extra as String;
            return UpdateFetchPages(masterType: masterType);
          },
        ),
        GoRoute(
          path: 'executive_master',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>? ?? {};
            return ExecutiveMaster(
              executiveName: args['executive_name'],
              isDisplayMode: args['isDisplayMode'] ?? false,
            );
          },
        ),
        GoRoute(
          path: 'customer_master',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>? ?? {};
            return CustomerMaster(
              customerName: args['customer_name'],
              isDisplayMode: args['isDisplayMode'] ?? false,
            );
          },
        ),
        GoRoute(
          path: 'item_master',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>? ?? {};
            return ItemMaster(
              itemName: args['item_name'],
              isDisplayMode: args['isDisplayMode'] ?? false,
            );
          },
        ),
        GoRoute(
          path: 'import_main',
          builder: (context, state) => const ImportMain(),
        ),
        GoRoute(
          path: 'import_item',
          builder: (context, state) => const ImportItem(),
        ),
        GoRoute(
          path: 'import_customer',
          builder: (context, state) => const ImportCustomer(),
        ),
        GoRoute(
          path: 'mysql_test',
          builder: (context, state) => const MysqlTest(),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Error occurred'),
          Text('Details: ${state.error}'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
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
