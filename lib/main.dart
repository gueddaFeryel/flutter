import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/auth_service.dart';
import 'services/intervention_service.dart';
import 'services/notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/home/calendar_screen.dart';
import 'screens/home/intervention_detail.dart';
import 'screens/home/intervention_form.dart';
import 'screens/home/rapport_form.dart';
import 'screens/home/list_rapport_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configuration to avoid Impeller crash
  debugDisableShadows = true;
  debugDisableClipLayers = true;
  
  await Firebase.initializeApp();
  await initializeDateFormatting('fr_FR', null);
  
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<InterventionService>(create: (_) => InterventionService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
      ],
      child: const MedicalApp(),
    ),
  );
}

class MedicalApp extends StatelessWidget {
  const MedicalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Intervention Médicale',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/home': (context) => const MainScreen(),
        '/calendar': (context) => CalendarScreen(),
        '/intervention-detail': (context) => InterventionDetailScreen(), // Removed const
        '/intervention-form': (context) => InterventionFormScreen(), // Removed const
        '/rapport-form': (context) => RapportFormScreen(), // Removed const
        '/rapports': (context) => ListRapportScreen(), // Removed const
      },
    );
  }
}