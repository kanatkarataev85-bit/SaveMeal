import 'package:flutter/material.dart';

import 'app.dart';
import 'services/supabase_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  runApp(const SaveMealApp());
}
