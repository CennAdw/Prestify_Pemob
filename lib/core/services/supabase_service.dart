import 'package:supabase/supabase.dart';

import '../constants/supabase_config.dart';

class SupabaseService {
  const SupabaseService._();

  static SupabaseClient? _client;

  static SupabaseClient get client {
    if (!isSupabaseConfigured) {
      throw StateError('Supabase URL dan anon key belum dikonfigurasi.');
    }

    return _client ??= SupabaseClient(supabaseUrl, supabaseAnonKey);
  }
}
