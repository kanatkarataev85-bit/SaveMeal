import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

bool get isSupabaseConfigured =>
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

Future<void> initializeSupabase() async {
  if (!isSupabaseConfigured) return;

  final uri = Uri.tryParse(supabaseUrl);
  if (uri == null ||
      !uri.hasScheme ||
      uri.host.isEmpty ||
      (uri.scheme != 'https' && uri.scheme != 'http')) {
    throw StateError('SUPABASE_URL must be a valid HTTP(S) URL.');
  }

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
}

String normalizePhoneNumber(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (phone.trimLeft().startsWith('+') || digits.startsWith('996')) {
    return '+$digits';
  }
  if (digits.length == 9) return '+996$digits';
  return '+$digits';
}

class SupabaseAuthService {
  SupabaseAuthService() : _client = Supabase.instance.client;

  final SupabaseClient _client;

  Future<AuthResponse> register({
    required String phone,
    required String password,
    required String fullName,
    required String address,
  }) {
    return _client.auth.signUp(
      phone: normalizePhoneNumber(phone),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'name': fullName.trim(),
        'phone': normalizePhoneNumber(phone),
        if (address.trim().isNotEmpty) 'address': address.trim(),
      },
    );
  }

  Future<AuthResponse> signIn({
    required String phone,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      phone: normalizePhoneNumber(phone),
      password: password,
    );
  }

  Future<AuthResponse> verifyPhone({
    required String phone,
    required String token,
  }) {
    return _client.auth.verifyOTP(
      phone: normalizePhoneNumber(phone),
      token: token,
      type: OtpType.sms,
    );
  }

  Future<void> resendPhoneVerification(String phone) {
    return _client.auth.resend(
      type: OtpType.sms,
      phone: normalizePhoneNumber(phone),
    );
  }

  Future<void> requireProfile(String userId) async {
    final profile = await _client
        .from('profilespro')
        .select('id')
        .eq('id', userId)
        .maybeSingle();
    if (profile == null) throw const ProfileNotFoundException();
  }
}

class ProfileNotFoundException implements Exception {
  const ProfileNotFoundException();
}
