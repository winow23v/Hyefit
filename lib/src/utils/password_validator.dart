import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// HIBP (HaveIBeenPwned) API를 사용한 비밀번호 유출 검증
class PasswordValidator {
  static const String _hibpApiUrl = 'https://api.pwnedpasswords.com/range';

  /// 비밀번호가 유출된 데이터베이스에 있는지 확인
  ///
  /// k-Anonymity 모델 사용:
  /// 1. 비밀번호를 SHA-1로 해싱
  /// 2. 해시의 처음 5자리만 API에 전송
  /// 3. API는 같은 접두사를 가진 모든 해시 반환
  /// 4. 클라이언트에서 나머지 부분을 비교
  ///
  /// 반환값: 유출 횟수 (0이면 안전)
  static Future<int> checkPasswordLeaked(String password) async {
    try {
      // 1. 비밀번호를 SHA-1로 해싱
      final bytes = utf8.encode(password);
      final hash = sha1.convert(bytes).toString().toUpperCase();

      // 2. 처음 5자리와 나머지 분리
      final prefix = hash.substring(0, 5);
      final suffix = hash.substring(5);

      // 3. HIBP API 호출
      final response = await http.get(
        Uri.parse('$_hibpApiUrl/$prefix'),
        headers: {
          'User-Agent': 'HyeFit-App',
          'Add-Padding': 'true', // 추가 보안을 위한 패딩
        },
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // 타임아웃 시 안전한 것으로 간주 (false negative)
          throw Exception('HIBP API timeout');
        },
      );

      if (response.statusCode != 200) {
        // API 오류 시 안전한 것으로 간주
        return 0;
      }

      // 4. 응답에서 해당 해시 찾기
      final lines = response.body.split('\n');
      for (final line in lines) {
        final parts = line.split(':');
        if (parts.length == 2 && parts[0].trim() == suffix) {
          return int.tryParse(parts[1].trim()) ?? 0;
        }
      }

      // 찾지 못함 = 안전
      return 0;
    } catch (e) {
      // 오류 발생 시 안전한 것으로 간주 (UX를 위해)
      return 0;
    }
  }

  /// 비밀번호 강도 검증 (기본 규칙)
  static String? validatePasswordStrength(String password) {
    if (password.isEmpty) {
      return '비밀번호를 입력해주세요';
    }

    if (password.length < 8) {
      return '비밀번호는 최소 8자 이상이어야 합니다';
    }

    // 영문, 숫자, 특수문자 중 2가지 이상 포함
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    final complexityCount = [hasLetter, hasDigit, hasSpecial].where((e) => e).length;
    if (complexityCount < 2) {
      return '영문, 숫자, 특수문자 중 2가지 이상을 포함해야 합니다';
    }

    return null; // 검증 통과
  }

  /// 전체 비밀번호 검증 (강도 + 유출 여부)
  static Future<String?> validatePassword(String password) async {
    // 1. 기본 강도 검증
    final strengthError = validatePasswordStrength(password);
    if (strengthError != null) {
      return strengthError;
    }

    // 2. 유출 여부 검증
    final leakCount = await checkPasswordLeaked(password);
    if (leakCount > 0) {
      return '이 비밀번호는 ${leakCount.toString()}회 유출된 기록이 있습니다. 다른 비밀번호를 사용해주세요.';
    }

    return null; // 모든 검증 통과
  }
}
