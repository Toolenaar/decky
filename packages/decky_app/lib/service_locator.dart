import 'package:get_it/get_it.dart';
import 'package:decky_core/controller/user_controller.dart';
import 'package:decky_core/controller/user_decks_controller.dart';
import 'package:decky_core/controller/user_collection_controller.dart';
import 'package:decky_core/controller/elasticsearch_service.dart';
import 'package:decky_core/providers/search_provider.dart';

final GetIt locator = GetIt.instance;

Future<void> setupServices() async {
  // Register UserController as singleton
  if (!locator.isRegistered<UserController>()) {
    locator.registerLazySingleton<UserController>(() => UserController());
  }

  // Register ElasticsearchService as singleton
  if (!locator.isRegistered<ElasticsearchService>()) {
    locator.registerLazySingleton<ElasticsearchService>(() => ElasticsearchService());
  }

  // Register SearchProvider as singleton
  if (!locator.isRegistered<SearchProvider>()) {
    locator.registerLazySingleton<SearchProvider>(() => SearchProvider(locator<ElasticsearchService>()));
  }

  // Register UserDecksController as singleton
  if (!locator.isRegistered<UserDecksController>()) {
    locator.registerLazySingleton<UserDecksController>(() => UserDecksController());
  }

  // Register UserCollectionController as singleton
  if (!locator.isRegistered<UserCollectionController>()) {
    locator.registerLazySingleton<UserCollectionController>(() => UserCollectionController());
  }
}

Future<void> initializeControllers() async {
  final userController = locator<UserController>();
  final userCollectionController = locator<UserCollectionController>();
  final userDecksController = locator<UserDecksController>();
  
  // Initialize collection controller with user's account ID
  if (userController.account != null) {
    userCollectionController.initialize(userController.account!.id);
    userDecksController.initialize(userController.account!.id);
  }
  
  // Listen to user account changes
  userController.accountSink.stream.listen((account) {
    if (account != null) {
      userCollectionController.initialize(account.id);
      userDecksController.initialize(account.id);
    }
  });
}

void disposeControllers() {
  // Dispose all data controllers on logout
  locator<UserController>().dispose();
}
