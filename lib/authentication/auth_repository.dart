import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:maruti_kirba_lighting_solutions/authentication/auth_exception.dart';
import 'package:maruti_kirba_lighting_solutions/authentication/auth_models.dart';
import 'package:maruti_kirba_lighting_solutions/authentication/auth_session.dart';

class AuthRepository {
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<AuthUser> _getUserFromCollection(
    String collection,
    String uid,
    UserRole role,
  ) async {
    final doc = await _firestore.collection(collection).doc(uid).get();
    if (!doc.exists) return Future.error('User not found in $collection');
    return AuthUser.fromMap(doc.data()!, uid, role);
  }

  Future<AuthUser> getAuthUser(String uid) async {
    try {
      return await _getUserFromCollection('admins', uid, UserRole.admin)
          .onError(
            (_, __) =>
                _getUserFromCollection('executives', uid, UserRole.executive),
          )
          .onError(
            (_, __) => _getUserFromCollection('users', uid, UserRole.user),
          );
    } on FirebaseException catch (e) {
      throw AuthException(
        code: e.code,
        message: 'Failed to fetch user data: ${e.message}',
      );
    }
  }

  Future<void> createUserRecord({
    required String uid,
    required Map<String, dynamic> data,
    required UserRole role,
    GeoPoint? location,
  }) async {
    try {
      final collection = role == UserRole.admin
          ? 'admins'
          : role == UserRole.executive
          ? 'executives'
          : 'users';

      await _firestore.collection(collection).doc(uid).set({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
        'last_login': FieldValue.serverTimestamp(),
        'lastLoginLocation': location,
      });
    } on FirebaseException catch (e) {
      throw AuthException(
        code: e.code,
        message: 'Failed to create user record: ${e.message}',
      );
    }
  }

  Future<void> deleteUserRecord(String uid) async {
    try {
      await Future.wait([
        _firestore.collection('admins').doc(uid).delete(),
        _firestore.collection('executives').doc(uid).delete(),
        _firestore.collection('users').doc(uid).delete(),
      ]);
    } on FirebaseException catch (e) {
      throw AuthException(
        code: e.code,
        message: 'Failed to delete user records: ${e.message}',
      );
    }
  }

  Future<void> createSession(AuthSession session) async {
    try {
      await _firestore
          .collection('sessions')
          .doc(session.sessionToken)
          .set(session.toMap());
    } on FirebaseException catch (e) {
      throw AuthException(
        code: e.code,
        message: 'Failed to create session: ${e.message}',
      );
    }
  }

  Future<void> endSession(String sessionToken) async {
    try {
      await _firestore.collection('sessions').doc(sessionToken).update({
        'isActive': false,
        'endTime': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AuthException(
        code: e.code,
        message: 'Failed to end session: ${e.message}',
      );
    }
  }

  Future<List<AuthSession>> getUserSessions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('sessions')
          .where('userId', isEqualTo: userId)
          .get();

      final user = await getAuthUser(userId);

      return snapshot.docs.map((doc) {
        return AuthSession.fromMap(doc.data(), user);
      }).toList();
    } on FirebaseException catch (e) {
      throw AuthException(
        code: e.code,
        message: 'Failed to fetch sessions: ${e.message}',
      );
    }
  }

  // In your AuthRepository class
  Future<void> updateUserLoginLocation({
    required String uid,
    required UserRole role,
    required GeoPoint? location,
  }) async {
    try {
      final collection = role == UserRole.admin
          ? 'admins'
          : role == UserRole.executive
          ? 'executives'
          : 'users';

      await _firestore.collection(collection).doc(uid).update({
        'lastLoginLocation': location,
        'last_login': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AuthException(
        code: e.code,
        message: 'Failed to update login location: ${e.message}',
      );
    }
  }

  Future<List<AuthUser>> getAllAdmins() async {
    try {
      final snapshot = await _firestore.collection('admins').get();
      return snapshot.docs.map((doc) {
        return AuthUser.fromMap(doc.data(), doc.id, UserRole.admin);
      }).toList();
    } on FirebaseException catch (e) {
      throw AuthException(
        code: e.code,
        message: 'Failed to fetch admins: ${e.message}',
      );
    }
  }

  Future<List<AuthUser>> getAllExecutives() async {
    try {
      final snapshot = await _firestore.collection('executives').get();
      return snapshot.docs.map((doc) {
        return AuthUser.fromMap(doc.data(), doc.id, UserRole.executive);
      }).toList();
    } on FirebaseException catch (e) {
      throw AuthException(
        code: e.code,
        message: 'Failed to fetch executives: ${e.message}',
      );
    }
  }
}
