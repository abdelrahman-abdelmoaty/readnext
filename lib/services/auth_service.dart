import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';
import '../utils/auth_utils.dart';
import '../utils/logger.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        "551166651209-qvoeuhseql1fvspc66rjmq8v6h18f32d.apps.googleusercontent.com",
  );
  final UserService _userService = UserService();

  User? _currentUser;
  AuthState _authState = AuthState.initial;
  String? _errorMessage;
  bool _isInitialized = false;

  // Constructor to listen for auth state changes
  AuthService() {
    Logger.authDebug('AuthService constructor called');
    _currentUser = _auth.currentUser;
    Logger.authDebug('Current user on init: ${_currentUser?.email ?? 'none'}');
    _setupAuthStateListener();
    _initializeAuthState();
  }

  // Getters
  User? get currentUser => _currentUser;
  AuthState get authState => _authState;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated =>
      _authState == AuthState.authenticated && _currentUser != null;
  bool get isLoading => _authState == AuthState.loading;

  // Set up auth state listener
  void _setupAuthStateListener() {
    Logger.authDebug('Setting up auth state listener');
    _auth.authStateChanges().listen((User? user) async {
      Logger.authDebug(
        'Auth state changed - User: ${user?.email ?? 'null'}, Initialized: $_isInitialized',
      );

      if (!_isInitialized) {
        Logger.authDebug('Auth state change ignored - not initialized yet');
        return; // Ignore until initialized
      }

      _currentUser = user;

      if (user != null) {
        Logger.authDebug(
          'User authenticated, setting auth state to authenticated',
        );
        // Just set authenticated state without aggressive validation
        _setAuthState(AuthState.authenticated);
        // Update last activity in background without awaiting
        _updateLastActivity();
      } else {
        Logger.authDebug('No user, setting auth state to unauthenticated');
        _setAuthState(AuthState.unauthenticated);
      }
    });
  }

  // Initialize auth state
  Future<void> _initializeAuthState() async {
    try {
      _setAuthState(AuthState.loading);

      if (_currentUser != null) {
        Logger.authDebug('Current user exists, setting authenticated state');
        _setAuthState(AuthState.authenticated);
        // Update last activity in background
        _updateLastActivity();
      } else {
        Logger.authDebug('No current user, setting unauthenticated state');
        _setAuthState(AuthState.unauthenticated);
      }
    } catch (e) {
      Logger.authDebug('Auth initialization error', e);
      _setAuthState(AuthState.unauthenticated);
    } finally {
      _isInitialized = true;
      Logger.authDebug('Auth service initialization completed');
    }
  }

  // Set authentication state
  void _setAuthState(AuthState state, {String? error}) {
    Logger.authDebug(
      'Auth state changing from ${_authState.name} to ${state.name}${error != null ? ' with error: $error' : ''}',
    );
    _authState = state;
    _errorMessage = error;
    notifyListeners();
    Logger.authDebug('Auth state changed successfully, notified listeners');
  }

  // Set error state
  void _setError(String message) {
    _setAuthState(AuthState.error, error: message);
  }

  // Update last activity timestamp (non-blocking)
  void _updateLastActivity() {
    if (_currentUser != null) {
      _userService.updateLastActivity().catchError((error) {
        Logger.authDebug('Failed to update last activity', error);
        // Don't throw error as this is not critical
      });
    }
  }

  // Clear authentication state - useful for debugging/recovery
  Future<void> clearAuthState() async {
    Logger.authDebug('Clearing authentication state...');
    try {
      // Clear Google Sign-In state
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Clear Firebase Auth state
      await _auth.signOut();

      _currentUser = null;
      _errorMessage = null;
      _setAuthState(AuthState.unauthenticated);

      Logger.authDebug('Authentication state cleared successfully');
    } catch (e) {
      Logger.authDebug('Error clearing auth state', e);
    }
  }

  // Email validation
  String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation
  String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  // Name validation
  String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Name is required';
    }

    if (name.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    return null;
  }

  // Create or update user document
  Future<void> _createOrUpdateUserDocument(
    User user, {
    String? name,
    String? authProvider,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      final userData = <String, dynamic>{
        'email': user.email ?? '',
        'lastLoginAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'uid': user.uid,
      };

      if (!userDoc.exists) {
        // Create new user document
        userData.addAll({
          'name': name ?? user.displayName ?? 'User',
          'createdAt': FieldValue.serverTimestamp(),
          'authProvider': authProvider ?? 'email',
          'profilePicture': user.photoURL,
          'isActive': true,
          'preferences': {
            'notifications': true,
            'darkMode': false,
            'language': 'English',
            'autoSync': true,
            'readingReminders': true,
          },
          'readingHistory': [],
          'favoriteBooks': [],
        });
        await userRef.set(userData);
      } else {
        // Update existing user document
        await userRef.update(userData);
      }
    } catch (e) {
      Logger.authDebug('Error creating/updating user document', e);
      throw Exception('Failed to create user profile');
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    Logger.authDebug('Starting email/password sign-in for: ${email.trim()}');
    try {
      // Don't set loading state - let UI handle loading locally

      // Validate inputs
      final emailError = validateEmail(email);
      if (emailError != null) {
        throw FirebaseAuthException(code: 'invalid-email', message: emailError);
      }

      // For sign-in, only check if password is not empty
      if (password.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-password',
          message: 'Password is required',
        );
      }

      // Sign in
      Logger.authDebug('Attempting Firebase sign-in...');
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      Logger.authDebug(
        'Firebase sign-in successful for: ${result.user?.email}',
      );

      // Update user document
      Logger.authDebug('Updating user document...');
      await _createOrUpdateUserDocument(result.user!, authProvider: 'email');
      Logger.authDebug('User document updated successfully');

      // Explicitly set auth state to authenticated after successful sign-in
      _currentUser = result.user;
      _setAuthState(AuthState.authenticated);
      Logger.authDebug(
        'Auth state explicitly set to authenticated after sign-in',
      );

      return result;
    } on FirebaseAuthException catch (e) {
      Logger.authDebug('Firebase auth error during sign-in', e);
      rethrow;
    } catch (e) {
      Logger.authDebug('Unexpected error during sign-in', e);
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    Logger.authDebug('Starting registration for: ${email.trim()}');
    try {
      // Don't set loading state - let UI handle loading locally

      // Validate inputs
      final emailError = validateEmail(email);
      if (emailError != null) {
        throw FirebaseAuthException(code: 'invalid-email', message: emailError);
      }

      final passwordError = validatePassword(password);
      if (passwordError != null) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: passwordError,
        );
      }

      final nameError = validateName(name);
      if (nameError != null) {
        throw FirebaseAuthException(code: 'invalid-name', message: nameError);
      }

      // Create user
      Logger.authDebug('Creating Firebase user account...');
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      Logger.authDebug('Firebase user created: ${result.user?.email}');

      // Update display name
      Logger.authDebug('Updating display name to: $name');
      await result.user!.updateDisplayName(name.trim());

      // Create user document
      Logger.authDebug('Creating user document in Firestore...');
      await _createOrUpdateUserDocument(
        result.user!,
        name: name.trim(),
        authProvider: 'email',
      );
      Logger.authDebug('Registration completed successfully');

      // Explicitly set auth state to authenticated after successful registration
      _currentUser = result.user;
      _setAuthState(AuthState.authenticated);
      Logger.authDebug(
        'Auth state explicitly set to authenticated after registration',
      );

      return result;
    } on FirebaseAuthException catch (e) {
      Logger.authDebug(
        'Registration failed with FirebaseAuthException: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      Logger.authDebug('Registration failed with unexpected error: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    Logger.authDebug('Starting Google sign-in...');
    try {
      // Don't set loading state - let UI handle loading locally

      // Trigger authentication flow (don't clear existing state as it may cause issues)
      Logger.authDebug('Triggering Google authentication flow...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        Logger.authDebug('Google sign-in was cancelled by user');
        throw FirebaseAuthException(
          code: 'sign-in-aborted',
          message: 'Google sign-in was cancelled',
        );
      }
      Logger.authDebug('Google user obtained: ${googleUser.email}');

      // Get authentication details with timeout
      Logger.authDebug('Getting authentication tokens...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        Logger.authDebug(
          'Missing auth tokens: accessToken=${googleAuth.accessToken != null}, idToken=${googleAuth.idToken != null}',
        );
        throw FirebaseAuthException(
          code: 'missing-auth-token',
          message: 'Failed to get authentication tokens',
        );
      }

      Logger.authDebug('Creating Firebase credential...');
      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      Logger.authDebug('Signing in to Firebase...');
      final result = await _auth.signInWithCredential(credential);
      Logger.authDebug('Firebase sign-in successful: ${result.user?.email}');

      // Create or update user document
      Logger.authDebug('Creating/updating user document...');
      await _createOrUpdateUserDocument(result.user!, authProvider: 'google');
      Logger.authDebug('Google sign-in completed successfully');

      // Explicitly set auth state to authenticated after successful Google sign-in
      _currentUser = result.user;
      _setAuthState(AuthState.authenticated);
      Logger.authDebug(
        'Auth state explicitly set to authenticated after Google sign-in',
      );

      return result;
    } on FirebaseAuthException catch (e) {
      Logger.authDebug('Firebase auth error during Google sign-in', e);
      rethrow;
    } catch (e) {
      Logger.authDebug('Unexpected error during Google sign-in', e);
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    Logger.authDebug('Starting sign-out process...');
    try {
      _setAuthState(AuthState.loading);

      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        Logger.authDebug('Signing out from Google...');
        await _googleSignIn.signOut();
      }

      // Sign out from Firebase
      Logger.authDebug('Signing out from Firebase...');
      await _auth.signOut();

      _currentUser = null;
      _setAuthState(AuthState.unauthenticated);
      Logger.authDebug('Sign-out completed successfully');
    } catch (e) {
      Logger.authDebug('Sign-out error', e);
      _setError('Failed to sign out');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      final emailError = validateEmail(email);
      if (emailError != null) {
        throw FirebaseAuthException(code: 'invalid-email', message: emailError);
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _getAuthErrorMessage(e),
      );
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'User not logged in',
        );
      }

      // Validate new password
      final passwordError = validatePassword(newPassword);
      if (passwordError != null) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: passwordError,
        );
      }

      // Re-authenticate user with current password
      final userEmail = user.email;
      if (userEmail == null) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'User email not found',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: userEmail,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      // Update last activity
      _updateLastActivity();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _getAuthErrorMessage(e),
      );
    }
  }

  // Get authentication error message
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using different sign-in method';
      case 'invalid-credential':
        return 'The credential is invalid or expired';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'sign-in-aborted':
        return 'Sign-in was cancelled';
      case 'missing-auth-token':
        return 'Authentication failed. Please try again';
      default:
        return e.message ?? 'An error occurred. Please try again';
    }
  }

  // Refresh user session (improved version)
  Future<void> refreshSession() async {
    try {
      if (_currentUser != null) {
        // Try to get a fresh token to validate session
        await _currentUser!.getIdToken(true);
        await _currentUser!.reload();
        _currentUser = _auth.currentUser;

        if (_currentUser != null) {
          _setAuthState(AuthState.authenticated);
          _updateLastActivity();
        } else {
          _setAuthState(AuthState.unauthenticated);
        }
      }
    } catch (e) {
      Logger.authDebug('Session refresh failed', e);
      // Only sign out for critical errors
      if (AuthUtils.isCriticalAuthError(e)) {
        await signOut();
      } else {
        // For network or temporary errors, keep the current state
        Logger.authDebug('Non-critical refresh error, maintaining session', e);
      }
    }
  }

  // Check if user session is still valid (lightweight check)
  Future<bool> isSessionValid() async {
    try {
      if (_currentUser == null) return false;

      // Simple check - just verify the user object is still valid
      final token = await _currentUser!.getIdToken(
        false,
      ); // Don't force refresh
      return token?.isNotEmpty ?? false;
    } catch (e) {
      Logger.authDebug('Session validity check failed', e);
      return false;
    }
  }

  // Check if Google Sign-In is available
  Future<bool> isGoogleSignInAvailable() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      return false;
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      return await _userService.getCurrentUserData();
    } catch (e) {
      Logger.authDebug('Error getting user data', e);
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? photoURL,
    String? bio,
  }) async {
    try {
      await _userService.updateUserProfile(
        name: name,
        photoURL: photoURL,
        bio: bio,
      );

      // Reload user
      await _currentUser?.reload();
      _currentUser = _auth.currentUser;
      notifyListeners();
    } catch (e) {
      Logger.authDebug('Error updating user profile', e);
      rethrow;
    }
  }

  // Update user preferences
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      await _userService.updateUserPreferences(preferences);
    } catch (e) {
      Logger.authDebug('Error updating user preferences', e);
      rethrow;
    }
  }

  @override
  void dispose() {
    AuthUtils.dispose();
    super.dispose();
  }

  // Handle authentication recovery - useful when auth state gets stuck
  Future<void> recoverAuthState() async {
    Logger.authDebug('Starting authentication recovery...');
    try {
      _setAuthState(AuthState.loading);

      // Clear any stuck state
      await clearAuthState();

      // Wait a moment for state to clear
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if there's a current user
      _currentUser = _auth.currentUser;

      if (_currentUser != null) {
        Logger.authDebug(
          'Found existing user during recovery: ${_currentUser!.email}',
        );
        _setAuthState(AuthState.authenticated);
        _updateLastActivity();
      } else {
        Logger.authDebug('No user found during recovery');
        _setAuthState(AuthState.unauthenticated);
      }
    } catch (e) {
      Logger.authDebug('Error during auth recovery', e);
      _setAuthState(AuthState.unauthenticated);
    }
  }
}
