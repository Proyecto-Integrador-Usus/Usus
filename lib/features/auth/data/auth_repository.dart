import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class AccountProfile {
  const AccountProfile(this.firstName, this.lastName, this.email, this.address);
  final String firstName;
  final String lastName;
  final String email;
  final String address;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}

abstract interface class AuthRepository {
  Future<AccountProfile> login(String email, String password);
  Future<AccountProfile> register(AccountProfile profile, String password);
}

// Datos volátiles para la maqueta. Python validará las credenciales.
class DemoAuthRepository implements AuthRepository {
  final _accounts = <String, ({AccountProfile profile, Digest verifier})>{};
  final _mac = Hmac(
    sha256,
    List.generate(32, (_) => Random.secure().nextInt(256)),
  );

  String _key(String email) => email.trim().toLowerCase();
  Digest _verify(String email, String password) =>
      _mac.convert(utf8.encode(jsonEncode([_key(email), password])));

  @override
  Future<AccountProfile> register(
    AccountProfile profile,
    String password,
  ) async {
    final key = _key(profile.email);
    if (_accounts.containsKey(key)) {
      throw const AuthFailure('Este correo ya tiene una cuenta.');
    }
    _accounts[key] = (profile: profile, verifier: _verify(key, password));
    return profile;
  }

  @override
  Future<AccountProfile> login(String email, String password) async {
    final entry = _accounts[_key(email)];
    if (entry == null || entry.verifier != _verify(email, password)) {
      throw const AuthFailure('Revisa tu correo y contraseña.');
    }
    return entry.profile;
  }
}
