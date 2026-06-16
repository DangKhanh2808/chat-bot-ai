import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../features/auth/data/datasources/firebase_auth_datasource.dart';
import '../features/auth/data/datasources/firebase_auth_datasource_impl.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Logger - Singleton for logging throughout app
  getIt.registerSingleton<Logger>(Logger());

  // Data Sources
  getIt.registerSingleton<FirebaseAuthDataSource>(
    FirebaseAuthDataSourceImpl(
      logger: getIt<Logger>(),
    ),
  );

  // Repositories
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      authDataSource: getIt<FirebaseAuthDataSource>(),
      logger: getIt<Logger>(),
    ),
  );

  // BLoCs
  getIt.registerSingleton<AuthBloc>(
    AuthBloc(
      authRepository: getIt<AuthRepository>(),
      logger: getIt<Logger>(),
    ),
  );
}
