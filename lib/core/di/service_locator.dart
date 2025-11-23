/// Dependency injection configuration using GetIt.
///
/// This file sets up the service locator pattern for the application,
/// providing centralized dependency management and inversion of control.
/// It registers all services, repositories, and utilities with their
/// appropriate lifetimes and dependencies.
///
/// Key Features:
/// - Singleton registration for shared services
/// - Factory registration for per-request instances
/// - Lazy initialization for performance
/// - Clean separation of concerns
///
/// Architecture:
/// - Services: Core business logic and external integrations
/// - Repositories: Data access layer abstractions
/// - Providers: State management layer
/// - Utilities: Shared helper functions
///
/// Usage:
/// ```dart
/// // Setup (call once in main)
/// await ServiceLocator.setup();
///
/// // Resolve dependencies
/// final logger = ServiceLocator.logger;
/// final config = ServiceLocator.appConfig;
/// ```
library;

import 'package:get_it/get_it.dart';
import '../../repositories/company_repository.dart';
import '../../repositories/client_repository.dart';
import '../../services/database_service.dart';
import '../../services/search_service.dart';
import '../logging/logger.dart';
import '../cache/cache_manager.dart';
import '../config/app_config.dart';
import '../../repositories/i_company_repository.dart';
import '../../repositories/i_client_repository.dart';
import '../logging/i_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service locator for dependency injection.
///
/// This class manages the registration and resolution of dependencies
/// throughout the application using the GetIt library.
final getIt = GetIt.instance;

class ServiceLocator {
  /// Initializes all dependencies.
  ///
  /// This method should be called once during app startup,
  /// typically in the main() function.
  static Future<void> setup() async {
    // App configuration
    getIt.registerLazySingleton<AppConfig>(() => AppConfig.fromEnvironment());

    // Core services
    getIt.registerLazySingleton<ILogger>(() => Logger(getIt<AppConfig>()));

    // SharedPreferences for caching
    final prefs = await SharedPreferences.getInstance();
    getIt.registerLazySingleton<SharedPreferences>(() => prefs);

    // Cache manager
    getIt.registerLazySingleton<CacheManager>(
      () => SharedPreferencesCacheManager(getIt<SharedPreferences>()),
    );

    // Database
    getIt.registerLazySingleton<DatabaseService>(
      () => DatabaseService(getIt<ILogger>()),
    );

    // Repositories
    getIt.registerLazySingleton<ICompanyRepository>(
      () => CompanyRepository(getIt<DatabaseService>()),
    );

    getIt.registerLazySingleton<IClientRepository>(
      () => ClientRepository(getIt<DatabaseService>()),
    );

    // Search service
    getIt.registerLazySingleton<SearchService>(
      () => SearchService(getIt<ILogger>()),
    );
  }

  // Convenience getters for commonly used dependencies
  static AppConfig get appConfig => getIt<AppConfig>();
  static ILogger get logger => getIt<ILogger>();
  static ICompanyRepository get companyRepository => getIt<ICompanyRepository>();
  static IClientRepository get clientRepository => getIt<IClientRepository>();
  static DatabaseService get databaseService => getIt<DatabaseService>();
  static CacheManager get cacheManager => getIt<CacheManager>();
  static SearchService get searchService => getIt<SearchService>();
}