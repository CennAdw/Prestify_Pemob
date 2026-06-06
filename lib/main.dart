//import 'package:flutter/material.dart';

//import 'app.dart';
//import 'core/services/supabase_service.dart';

//Future<void> main() async {
//  WidgetsFlutterBinding.ensureInitialized();
//  await SupabaseService.initialize();
//  runApp(const UpiConnectApp());
//}
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('TEST'),
        ),
      ),
    ),
  );
}
