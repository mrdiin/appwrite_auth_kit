import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/widgets.dart';

extension AppwriteAuthKitExt on BuildContext {
  AuthNotifier get authNotifier => AppwriteAuthKit.of(this);
}

class AppwriteAuthKit extends InheritedNotifier<AuthNotifier> {
  AppwriteAuthKit({
    Key? key,
    required Client client,
    required Widget child,
  }) : super(
          key: key,
          notifier: AuthNotifier(client),
          child: child,
        );

  @override
  bool updateShouldNotify(InheritedNotifier<AuthNotifier> oldWidget) {
    return oldWidget.notifier != notifier;
  }

  static AuthNotifier of(BuildContext context) {
    final AuthNotifier? result =
        context.dependOnInheritedWidgetOfExactType<AppwriteAuthKit>()?.notifier;
    assert(result != null, 'No AuthNotifier found in context');
    return result!;
  }
}

enum AuthStatus {
  uninitialized,
  authenticated,
  authenticating,
  unauthenticated,
}

class AuthNotifier extends ChangeNotifier {
  late final Account _account;
  final Client _client;
  AuthStatus _status = AuthStatus.uninitialized;
  models.Account? _user;
  String? _error;
  late bool _loading;

  AuthNotifier(Client client) : _client = client {
    _error = '';
    _loading = true;
    _account = Account(client);
    _getUser();
  }

  Account get account => _account;
  Client get client => _client;
  String? get error => _error;
  bool get isLoading => _loading;
  models.Account? get user => _user;
  AuthStatus get status => _status;

  Future _getUser({bool notify = true}) async {
    try {
      _user = await _account.get();
      _status = AuthStatus.authenticated;
    } on AppwriteException catch (e) {
      _status = AuthStatus.unauthenticated;
      _error = e.message;
    } finally {
      _loading = false;
      if (notify) {
        notifyListeners();
      }
    }
  }

  Future<bool> deleteSession({String sessionId = 'current'}) async {
    try {
      await _account.deleteSession(sessionId: sessionId);
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      return false;
    }
  }

  Future<bool> deleteSessions() async {
    try {
      await _account.deleteSessions();
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      return false;
    }
  }

  Future<bool> createEmailSession({
    required String email,
    required String password,
    bool notify = true,
  }) async {
    _status = AuthStatus.authenticating;
    if (notify) {
      notifyListeners();
    }
    try {
      await _account.createEmailSession(email: email, password: password);
      _getUser(notify: notify);
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      if (notify) {
        notifyListeners();
      }
      return false;
    }
  }

  Future<bool> createPhoneSession({
    required String userId,
    required String number,
  }) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      await _account.createPhoneSession(userId: userId, phone: number);
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePhoneSession({
    required String userId,
    required String secret,
  }) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      await _account.updatePhoneSession(userId: userId, secret: secret);
      await _getUser();
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createAnonymousSession() async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      await _account.createAnonymousSession();
      _getUser();
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createMagicURLSession({
    required String email,
    String userId = 'unique()',
    String? url,
  }) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      await _account.createMagicURLSession(
          userId: userId, email: email, url: url);
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMagicURLSession({
    required String userId,
    required String secret,
  }) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      await _account.updateMagicURLSession(userId: userId, secret: secret);
      _getUser();
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<models.Jwt?> createJWT() async {
    try {
      return await _account.createJWT();
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  /// Create account
  ///
  Future<models.Account?> create({
    required String email,
    required String password,
    String userId = 'unique()',
    bool notify = true,
    bool newSession = true,
    String? name,
  }) async {
    _status = AuthStatus.authenticating;
    if (notify) {
      notifyListeners();
    }
    try {
      final user = await _account.create(
          userId: userId, name: name, email: email, password: password);
      _error = '';
      if (newSession) {
        await createEmailSession(email: email, password: password);
      }
      return user;
    } on AppwriteException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      if (notify) {
        notifyListeners();
      }
      return null;
    }
  }

  Future<bool> updateStatus() async {
    try {
      await _account.updateStatus();
      _getUser();
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<models.Account?> updatePrefs(
      {required Map<String, dynamic> prefs}) async {
    try {
      _user = await _account.updatePrefs(prefs: prefs);
      notifyListeners();
      return _user;
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<models.LogList?> listLogs({List<String>? queries}) async {
    try {
      return await _account.listLogs(queries: queries);
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> createOAuth2Session({
    required String provider,
    String? success,
    String? failure,
    List<String>? scopes,
  }) async {
    try {
      await _account.createOAuth2Session(
        provider: provider,
        success: success,
        failure: failure,
        scopes: scopes,
      );
      _getUser();
      return true;
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<models.Session?> getSession({required String sessionId}) async {
    try {
      return await _account.getSession(sessionId: sessionId);
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<models.SessionList?> getSessions() async {
    try {
      return await _account.listSessions();
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<models.Account?> updateName({required String name}) async {
    try {
      _user = await _account.updateName(name: name);
      notifyListeners();
      return _user;
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<models.Account?> updatePhone({
    required String number,
    required String password,
  }) async {
    try {
      _user = await _account.updatePhone(phone: number, password: password);
      notifyListeners();
      return _user;
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<models.Account?> updateEmail({
    required String email,
    required String password,
  }) async {
    try {
      _user = await _account.updateEmail(email: email, password: password);
      notifyListeners();
      return _user;
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<models.Account?> updatePassword({
    required String password,
    String? oldPassword,
  }) async {
    try {
      _user = await _account.updatePassword(
          password: password, oldPassword: oldPassword);
      notifyListeners();
      return _user;
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  //createRecovery
  Future<models.Token?> createRecovery({
    required String email,
    required String url,
  }) async {
    try {
      return await _account.createRecovery(email: email, url: url);
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  //updateRecovery
  Future<models.Token?> updateRecovery({
    required String userId,
    required String password,
    required String passwordAgain,
    required String secret,
  }) async {
    try {
      return await _account.updateRecovery(
          userId: userId,
          password: password,
          passwordAgain: passwordAgain,
          secret: secret);
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  //createVerification
  Future<models.Token?> createVerification({required String url}) async {
    try {
      return await _account.createVerification(url: url);
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  //updateVerification
  Future<models.Token?> updateVerification({
    required String userId,
    required String secret,
  }) async {
    try {
      return await _account.updateVerification(userId: userId, secret: secret);
    } on AppwriteException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }
}
