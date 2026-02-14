import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static String get url => (dotenv.env['SUPABASE_URL'] ?? '').trim();
  static String get anonKey => (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim();
  static String? get emailRedirectUrl {
    final value = dotenv.env['SUPABASE_EMAIL_REDIRECT_URL']?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static Future<void> initialize() async {
    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL 또는 SUPABASE_ANON_KEY가 비어 있습니다. '
        '.env 로드 여부를 확인하세요.',
      );
    }
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
}
