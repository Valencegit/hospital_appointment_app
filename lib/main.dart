import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/department_provider.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/firestore_service.dart';
import 'services/appointment_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Lock application orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase Core & Services
  await FirebaseService.initialize();

  // Register the FCM background message handler before runApp.
  // Must be called after Firebase.initializeApp().
  await NotificationService.initializeBackground();

  // Initialize singleton services
  final firestoreService = FirestoreService();
  final authService = AuthService(firestoreService: firestoreService);
  final appointmentService = AppointmentService();

  runApp(
    MultiProvider(
      providers: [
        Provider<FirestoreService>.value(value: firestoreService),
        Provider<AuthService>.value(value: authService),
        Provider<AppointmentService>.value(value: appointmentService),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            authService: authService,
            firestoreService: firestoreService,
          ),
        ),
        ChangeNotifierProvider<AppointmentProvider>(
          create: (_) => AppointmentProvider(),
        ),
        ChangeNotifierProvider<DepartmentProvider>(
          create: (_) => DepartmentProvider(),
        ),
      ],
      child: const HospitalAppointmentApp(),
    ),
  );
}

/// Root application widget for CarePulse Hospital.
class HospitalAppointmentApp extends StatefulWidget {
  const HospitalAppointmentApp({super.key});

  @override
  State<HospitalAppointmentApp> createState() => _HospitalAppointmentAppState();
}

class _HospitalAppointmentAppState extends State<HospitalAppointmentApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _appRouter = AppRouter(authProvider: authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: _appRouter.router,
    );
  }
}
