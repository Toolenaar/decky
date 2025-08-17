import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:decky_core/controller/user_controller.dart';
import 'package:decky_core/providers/theme_provider.dart';
import 'package:decky_admin/router/app_router.dart';
import 'package:decky_admin/services/service_locator.dart';
import 'firebase_options.dart';

final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Setup dependency injection
  await setupServices();
  
  // Initialize UserController
  await getIt<UserController>().init();
  
  // Initialize all data controllers
  await initializeControllers();
  
  // Initialize AuthStateNotifier after services are ready
  AppRouter.initializeAuthNotifier();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp.router(
      title: 'Decky Admin',
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
