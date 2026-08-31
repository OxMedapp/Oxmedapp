import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/api_client.dart';
import 'theme/app_theme.dart';
import 'screens/sign_in_screen.dart';
import 'screens/home_shell.dart';
import 'screens/patient_screen.dart';
import 'screens/assessment_screen.dart';
import 'screens/ai_review_screen.dart';
import 'screens/smart_routing_screen.dart';
import 'screens/referral_screen.dart';
import 'screens/tracking_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await ApiClient.init();
  runApp(const OxMedApp());
}

class OxMedApp extends StatelessWidget {
  const OxMedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OxMed PharmaLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/signin',
      routes: {
        '/signin': (context) => const SignInScreen(),
        '/home': (context) => const HomeShell(),
        '/patient': (context) => const PatientScreen(),
        '/assessment': (context) => const AssessmentScreen(),
        '/ai-review': (context) => const AIReviewScreen(),
        '/routing': (context) => const SmartRoutingScreen(),
        '/referral': (context) => const ReferralCreatedScreen(),
        '/tracking': (context) => const TrackingScreen(),
      },
    );
  }
}