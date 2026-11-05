import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Session {
  const Session({required this.token, this.displayName = ''});

  final String token;
  final String displayName;
}

/// Holds the login token in the iOS Keychain and notifies the widget tree on
/// sign-in / sign-out.
class SessionStore extends ValueNotifier<Session?> {
  SessionStore._() : super(null);

  static final SessionStore instance = SessionStore._();

  static const _kToken = 'auth_token';
  static const _kName = 'auth_name';

  final FlutterSecureStorage _storage = FlutterSecureStorage();

  String? token() => value?.token;

  Future<void> load() async {
    final token = await _storage.read(key: _kToken);
    if (token == null || token.isEmpty) {
      value = null;
      return;
    }
    value = Session(
      token: token,
      displayName: await _storage.read(key: _kName) ?? '',
    );
  }

  Future<void> save(Session s) async {
    await _storage.write(key: _kToken, value: s.token);
    await _storage.write(key: _kName, value: s.displayName);
    value = s;
  }

  Future<void> clear() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kName);
    value = null;
  }
}
