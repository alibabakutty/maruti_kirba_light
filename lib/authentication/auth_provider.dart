import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:maruti_kirba_lighting_solutions/authentication/auth_exception.dart';
import 'package:maruti_kirba_lighting_solutions/authentication/auth_models.dart';
import 'package:maruti_kirba_lighting_solutions/authentication/auth_service.dart';
import 'package:maruti_kirba_lighting_solutions/authentication/auth_session.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  AuthUser? _currentUser;
  AuthSession? _currentSession;
  bool _isLoading = false;
  String? _error;

  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await _restoreSession(currentUser.uid);
      }

      _authService.authStateChanges.listen((user) async {
        if (user != null) {
          await _restoreSession(user.uid);
        } else {
          _currentUser = null;
          _currentSession = null;
        }
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  AuthSession? get currentSession => _currentSession;
  AuthUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isExecutive => _currentUser?.isExecutive ?? false;
  bool get canAccessOrderMaster => isAdmin || isExecutive;

  Future<void> _restoreSession(String uid) async {
    try {
      _currentUser = await _authService.getCurrentAuthUser();
      final sessions = await _authService.getUserSessions(uid);

      if (sessions.any((s) => s.isActive)) {
        _currentSession = sessions.firstWhere((s) => s.isActive);
      } else {
        final sessionToken = await _authService.generateSessionToken();
        _currentSession = AuthSession(
          user: _currentUser!,
          sessionToken: sessionToken,
        );
        await _authService.createSession(_currentSession!);
      }
    } catch (e) {
      throw AuthException(
        code: 'session-restore-failed',
        message: 'Could not restore session',
      );
    }
  }

  Future<void> _handleAuthOperation(
    Future<AuthUser> Function() operation,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await operation();
      if (_currentUser != null) {
        final sessionToken = await _authService.generateSessionToken();
        _currentSession = AuthSession(
          user: _currentUser!,
          sessionToken: sessionToken,
        );
        await _authService.createSession(_currentSession!);
      }
    } on AuthException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> adminSignIn({
    required String email,
    required String password,
    required GeoPoint loginLocation,
  }) => _handleAuthOperation(
    () => _authService.adminSignIn(
      email: email,
      password: password,
      loginLocation: loginLocation,
    ),
  );

  Future<void> supplierSignIn({
    required String email,
    required String password,
    required GeoPoint loginLocation,
  }) => _handleAuthOperation(
    () => _authService.executiveSignIn(
      email: email,
      password: password,
      loginLocation: loginLocation,
    ),
  );

  Future<void> createAdminAccount(AdminSignUpData data) =>
      _handleAuthOperation(() => _authService.createAdminAccount(data));

  Future<void> createSupplierAccount(ExecutiveSignUpData data) =>
      _handleAuthOperation(() => _authService.createExecutiveAccount(data));

  Future<void> signOut() async {
    try {
      if (_currentSession != null) {
        await _authService.signOut(sessionToken: _currentSession!.sessionToken);
      } else {
        await _authService.signOut();
      }
      _currentUser = null;
      _currentSession = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteAccount({required String currentPassword}) async {
    await _handleAuthOperation(() async {
      await _authService.deleteAccount(currentPassword: currentPassword);
      throw AuthException(
        code: 'user-deleted',
        message: 'User account deleted',
      );
    });
    _currentUser = null;
    _currentSession = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<List<AuthUser>> getAllAdmins() async {
    _isLoading = true;
    notifyListeners();

    try {
      final admins = await _authService.getAllAdmins();
      _isLoading = false;
      notifyListeners();
      return admins;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<List<AuthUser>> getAllExecutives() async {
    _isLoading = true;
    notifyListeners();

    try {
      final executives = await _authService.getAllExecutives();
      _isLoading = false;
      notifyListeners();
      return executives;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}