import 'package:get_it/get_it.dart';
import 'package:decky_core/controller/user_controller.dart';
import '../controllers/card_controller.dart';
import '../controllers/deck_controller.dart';
import '../controllers/sealed_product_controller.dart';
import '../controllers/set_controller.dart';
import '../controllers/token_controller.dart';

final GetIt locator = GetIt.instance;

Future<void> setupServices() async {
  // Register UserController as singleton
  if (!locator.isRegistered<UserController>()) {
    locator.registerLazySingleton<UserController>(() => UserController());
  }
  
  // Register data controllers as singletons
  locator.registerLazySingleton<CardController>(() => CardController());
  locator.registerLazySingleton<DeckController>(() => DeckController());
  locator.registerLazySingleton<SealedProductController>(() => SealedProductController());
  locator.registerLazySingleton<SetController>(() => SetController());
  locator.registerLazySingleton<TokenController>(() => TokenController());
}

Future<void> initializeControllers() async {
  // Initialize all controllers after login
  await locator<CardController>().init();
  await locator<DeckController>().init();
  await locator<SealedProductController>().init();
  await locator<SetController>().init();
  await locator<TokenController>().init();
}

void disposeControllers() {
  // Dispose all data controllers on logout
  locator<CardController>().dispose();
  locator<DeckController>().dispose();
  locator<SealedProductController>().dispose();
  locator<SetController>().dispose();
  locator<TokenController>().dispose();
}