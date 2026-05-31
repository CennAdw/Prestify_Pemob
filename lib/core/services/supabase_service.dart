import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_config.dart';

class SupabaseService {
  const SupabaseService._();

  static bool _isInitialized = false;

  static bool get isReady => isSupabaseConfigured && _isInitialized;

  static Future<void> initialize() async {
    if (!isSupabaseConfigured) {
      throw StateError('Supabase URL dan anon key belum dikonfigurasi.');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: kDebugMode,
    );
    _isInitialized = true;
  }

  static SupabaseClient get client {
    if (!isSupabaseConfigured) {
      throw StateError('Supabase URL dan anon key belum dikonfigurasi.');
    }
    if (!_isInitialized) {
      throw StateError('Supabase belum diinisialisasi.');
    }

    return Supabase.instance.client;
  }

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}
