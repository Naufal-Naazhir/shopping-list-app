import 'package:appwrite/appwrite.dart';
import 'package:belanja_praktis/config/app_router.dart';
import 'package:belanja_praktis/config/app_theme.dart';
import 'package:belanja_praktis/config/appwrite_config.dart';
import 'package:belanja_praktis/data/repositories/auth_repository.dart';
import 'package:belanja_praktis/data/repositories/auth_repository_impl.dart';
import 'package:belanja_praktis/data/repositories/pantry_repository.dart';
import 'package:belanja_praktis/data/repositories/pantry_repository_impl.dart';
import 'package:belanja_praktis/data/repositories/payment_repository.dart';
import 'package:belanja_praktis/data/repositories/shopping_list_repository.dart';
import 'package:belanja_praktis/data/repositories/shopping_list_repository_impl.dart';
import 'package:belanja_praktis/presentation/bloc/pantry_bloc.dart';
import 'package:belanja_praktis/presentation/bloc/payment/payment_bloc.dart';
import 'package:belanja_praktis/presentation/bloc/payment_status_bloc.dart';
import 'package:belanja_praktis/presentation/bloc/shopping_list_bloc.dart';
import 'package:belanja_praktis/presentation/services/notification_service.dart';
import 'package:belanja_praktis/services/ai_service.dart';
import 'package:belanja_praktis/services/appwrite_user_service.dart'; // Tambahkan ini
import 'package:belanja_praktis/services/local_storage_service.dart';
import 'package:belanja_praktis/services/theme_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencies({bool isTest = false}) async {
  final client = Client()
    ..setEndpoint(AppwriteConfig.endpoint)
    ..setProject(AppwriteConfig.projectId);
  final account = Account(client);
  final databases = Databases(client);
  final realtime = Realtime(client);
  final functions = Functions(client);
  getIt.registerSingleton<Client>(client);
  getIt.registerSingleton<Account>(account);
  getIt.registerSingleton<Databases>(databases);
  getIt.registerSingleton<Realtime>(realtime);
  getIt.registerSingleton<Functions>(functions);

  // Daftarkan AppwriteUserService
  getIt.registerSingleton<AppwriteUserService>(AppwriteUserService());

  if (!isTest) {
    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.init();
    getIt.registerSingleton<NotificationService>(notificationService);

    if (!kIsWeb) {
      MobileAds.instance.initialize();
    }
  }

  getIt.registerSingleton<PantryRepository>(
    PantryRepositoryImpl(
      getIt<Databases>(),
      getIt<Realtime>(),
      getIt<Account>(),
    ),
  );
  getIt.registerSingleton<ShoppingListRepository>(
    ShoppingListRepositoryImpl(
      getIt<Databases>(),
      getIt<Realtime>(),
      getIt<Account>(),
      getIt<PantryRepository>(),
    ),
  );
  await getIt<ShoppingListRepository>().init();

  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<LocalStorageService>(LocalStorageService(prefs));

  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(getIt<Client>(), getIt<Account>(), getIt<Databases>()),
  );

  getIt.registerSingleton<PaymentRepository>(
    PaymentRepository(functions: getIt<Functions>()),
  );

  getIt.registerSingleton<AIService>(AIService(getIt<LocalStorageService>()));

  getIt.registerSingleton<ThemeService>(
    ThemeService(getIt<LocalStorageService>()),
  );

  await getIt<AuthRepository>().initializePremiumAccounts();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ShoppingListBloc(
            getIt<ShoppingListRepository>(),
            getIt<AuthRepository>(),
          )..add(LoadShoppingLists()),
        ),
        BlocProvider(
          create: (context) {
            return PantryBloc(
              getIt<PantryRepository>(),
              getIt<ShoppingListRepository>(),
            );
          },
        ),
        BlocProvider(
          create: (context) =>
              PaymentBloc(paymentRepository: getIt<PaymentRepository>()),
        ),
        BlocProvider(create: (context) => PaymentStatusBloc(getIt<Client>())),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: getIt<ThemeService>().themeModeNotifier,
        builder: (context, themeMode, child) {
          return MaterialApp.router(
            title: 'Belanja Praktis',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
