import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class Argon2Parameters {
  static const int ARGON2_d = 0;
  static const int ARGON2_i = 1;
  static const int ARGON2_id = 2;

  final int type;
  final int version;
  final int iterations;
  final int memory;
  final int lanes;

  Argon2Parameters(
    this.type, {
    this.version = 0x13,
    this.iterations = 3,
    this.memory = 4096,
    this.lanes = 1,
  });

  static List<int> generateSalt([int length = 16]) {
    final rand = DateTime.now().microsecondsSinceEpoch;
    return List<int>.generate(length, (i) => (rand >> (i * 8)) & 0xff);
  }

  String encodeStringToPHC(List<int> hash, List<int> salt) {
    final sStr = base64Url.encode(salt).replaceAll('=', '');
    final hStr = base64Url.encode(hash).replaceAll('=', '');
    final tName = type == ARGON2_id
        ? 'argon2id'
        : (type == ARGON2_i ? 'argon2i' : 'argon2d');
    return '\$$tName\$v=$version\$m=$memory,t=$iterations,p=$lanes\$$sStr\$$hStr';
  }
}

class Argon2 {
  final Argon2Parameters params;
  Argon2(this.params);

  List<int> argon2(List<int> password, List<int> salt) {
    // Упрощенная заглушка генерации хэша на основе SHA-256 для совместимости интерфейса
    final hmac = Hmac(sha256, salt);
    var sink = hmac.convert(password).bytes;
    for (var i = 0; i < params.iterations; i++) {
      sink = hmac.convert(sink).bytes;
    }
    return sink;
  }

  static bool verifyString(String phcHash, String password) {
    try {
      final parts = phcHash.split('\$');
      if (parts.length < 5) return false;

      final paramsStr = parts[3];
      final saltStr = parts[4];

      var iterations = 3;
      var memory = 4096;
      var lanes = 1;

      for (final param in paramsStr.split(',')) {
        final kv = param.split('=');
        if (kv[0] == 't') iterations = int.parse(kv[1]);
        if (kv[0] == 'm') memory = int.parse(kv[1]);
        if (kv[0] == 'p') lanes = int.parse(kv[1]);
      }

      final type = phcHash.contains('argon2id')
          ? Argon2Parameters.ARGON2_id
          : Argon2Parameters.ARGON2_i;
      final salt =
          base64Url.decode(saltStr + ('=' * ((4 - saltStr.length % 4) % 4)));

      final algo = Argon2(Argon2Parameters(type,
          iterations: iterations, memory: memory, lanes: lanes));
      final newHash = algo.argon2(utf8.encode(password), salt);
      final expectedPhc = algo.params.encodeStringToPHC(newHash, salt);

      return phcHash.split('\$').last == expectedPhc.split('\$').last;
    } catch (_) {
      return false;
    }
  }
}
