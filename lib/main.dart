import 'dart:async';
import 'package:bucketlist/screens/profile_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:bucketlist/firebase_options.dart';
import 'package:bucketlist/providers/auth_provider.dart';
import 'package:bucketlist/providers/user_provider.dart';
import 'package:bucketlist/services/ad_factory_manager.dart';
import 'package:bucketlist/services/ad_service.dart';
import 'package:bucketlist/services/firebase_services_factory.dart';
import 'package:bucketlist/services/local_storage_service.dart';
import 'package:bucketlist/services/sync_service.dart';
import 'package:bucketlist/viewmodels/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import '../viewmodels/bucket_list_view_model.dart';
import 'mainScreen.dart';
import 'package:flutter/services.dart';
import 'utils/theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  late SharedPreferences _prefs;
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize SharedPreferences first
  final prefs = await SharedPreferences.getInstance();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Create the Firebase services factory
  final servicesFactory = FirebaseServicesFactory();

  // Initialize Firebase App Check with better error handling
  try {
    print('🔥 Initializing Firebase App Check...');
    await servicesFactory.appCheckService.initialize();
    print('✅ Firebase App Check initialized successfully');

    // Test App Check token generation
    final token = await servicesFactory.appCheckService.getToken();
    if (token.isNotEmpty) {
      print('✅ App Check token generated successfully');
      print('Token preview: ${token.substring(0, 20)}...');
    } else {
      print('⚠️ App Check token generation failed - using fallback');
    }
  } catch (e) {
    print('❌ Warning: Firebase App Check initialization failed: $e');
    print('This is expected in development - App will use debug tokens');
    // In development, this is normal and the app will work with debug tokens
  }

  // Test Firebase Auth status
  try {
    final currentUser = servicesFactory.authService.currentUser;
    if (currentUser != null) {
      print(
        '✅ User authenticated: ${currentUser.uid} (Anonymous: ${currentUser.isAnonymous})',
      );
    } else {
      print('⚠️ No user authenticated - will sign in anonymously');
    }
  } catch (e) {
    print('❌ Error checking auth status: $e');
  }

  // Initialize local storage service and wait for it to be ready
  final localStorageService = await LocalStorageService.create();
  await localStorageService.initialize();

  // Create the sync service only after local storage is initialized
  final syncService = SyncService(
    firebaseService: servicesFactory.firestoreService,
    localStorageService: localStorageService,
  );

  // Initialize theme provider with the same SharedPreferences instance
  final themeProvider = ThemeProvider();
  themeProvider._prefs = prefs;
  await themeProvider.initialize();

  // Initialize AdMob service
  final adService = await AdService.getInstance();

  // Register native ad factories
  AdFactoryManager.registerNativeAdFactories();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: [
        // Provide the Firebase services
        Provider.value(value: servicesFactory),

        // Auth provider with Firebase services
        ChangeNotifierProvider(
          create:
              (_) => AuthProvider(
                authService: servicesFactory.authService,
                firestoreService: servicesFactory.firestoreService,
              ),
        ),

        // User provider for avatar and profile management
        ChangeNotifierProvider(create: (_) => UserProvider()),

        // Auth ViewModel with Firebase auth service
        ChangeNotifierProvider(
          create:
              (_) => AuthViewModel(authService: servicesFactory.authService),
        ),

        // Bucket List ViewModel with sync service
        ChangeNotifierProvider(
          create: (_) => BucketListViewModel(syncService: syncService),
        ),

        // Theme provider
        ChangeNotifierProvider.value(value: themeProvider),

        // Ad service
        Provider.value(value: adService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'BucketList',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthWrapper(), // Use AuthWrapper to initialize user data
      routes: {'/profile': (context) => const ProfileScreen()},
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          // Initialize user data when authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final userProvider = Provider.of<UserProvider>(
              context,
              listen: false,
            );
            userProvider.initializeUser();
          });
        }

        return const Mainscreen();
      },
    );
  }
}
