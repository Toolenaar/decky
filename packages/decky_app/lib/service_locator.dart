import 'package:get_it/get_it.dart';
import 'package:decky_core/controller/user_controller.dart';
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
}

Future<void> initializeControllers() async {}

void disposeControllers() {
  // Dispose all data controllers on logout
  locator<UserController>().dispose();
}
