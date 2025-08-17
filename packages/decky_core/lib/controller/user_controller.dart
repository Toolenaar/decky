import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decky_core/model/account.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/subjects.dart';

enum LoginState { loggedOut, loggedIn, loggingOff }

class UserController {
  final _auth = FirebaseAuth.instance;
  // BehaviorSubject<Account?> accountSink = BehaviorSubject.seeded(null);
  final BehaviorSubject<LoginState> loggedinSink = BehaviorSubject.seeded(LoginState.loggedOut);

  User? loggedInUser;
  //Account
  final BehaviorSubject<Account?> accountSink = BehaviorSubject.seeded(null);
  Account? get account => accountSink.value;
  // Auth state streams
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  Stream<LoginState> get loginStateStream => loggedinSink.stream;

  // Current state getters
  User? get currentUser => _auth.currentUser;
  LoginState get currentLoginState => loggedinSink.value;

  Future init() async {
    await Future.delayed(const Duration(milliseconds: 2000)); //show splash screen

    _auth.authStateChanges().listen((event) async {
      loggedInUser = event;
      if (loggedInUser != null) {
        await _fetchUserAfterLogin();
        loggedinSink.add(LoginState.loggedIn);
      } else {
        loggedinSink.add(LoginState.loggedOut);
      }
    });
  }

  Future<void> _fetchUserAfterLogin() async {
    final account = await Account.getAccount(loggedInUser!.uid);
    if (account == null) {
      //create account
      await signOut();

      return;
    }
    accountSink.add(account);
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return credential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      // Check if this is a keychain error on macOS
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('keychain') || errorString.contains('nslocalized')) {
        // Try signing in without persistence (session only)
        throw FirebaseAuthException(
          code: 'keychain-error',
          message:
              'Keychain access error. Please check your macOS keychain settings or run the app with: flutter run -d macos --dart-define=FIREBASE_AUTH_PERSIST=false',
        );
      }
      throw Exception('Authentication failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      loggedinSink.add(LoginState.loggingOff);
      await _auth.signOut();
    } catch (e) {
      // Reset state if sign out fails
      if (loggedInUser != null) {
        loggedinSink.add(LoginState.loggedIn);
      }
      rethrow;
    }
  }

  // Create user with email and password (for future use)
  Future<UserCredential> createUserWithEmailAndPassword({required String email, required String password}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return credential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Send password reset email (for future use)
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  // Dispose method for cleanup
  void dispose() {
    loggedinSink.close();
  }
}
