import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'app/app_router.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://eqdknprvoksjgktjhkyw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVxZGtucHJ2b2tzamdrdGpoa3l3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxMTM4MjEsImV4cCI6MjA4NzY4OTgyMX0.Hl1YMQFpbbCQLwXCg-6ZWlvZoQ6r-vf--o-AuLE_GmE',
  );

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Yurt Yoklama',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      routerConfig: AppRouter.router,
    );
  }
}
