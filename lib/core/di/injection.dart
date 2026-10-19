import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsphere/core/network/api_client.dart';
import 'package:shopsphere/core/network/connectivity_cubit.dart';
import 'package:shopsphere/core/session/session_manager.dart';
import 'package:shopsphere/core/storage/token_storage.dart';
import 'package:shopsphere/core/theme/theme_cubit.dart';
import 'package:shopsphere/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:shopsphere/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shopsphere/features/auth/domain/repositories/auth_repository.dart';
import 'package:shopsphere/features/auth/domain/usecases/auth_usecases.dart';
import 'package:shopsphere/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shopsphere/features/auth/presentation/bloc/login_cubit.dart';
import 'package:shopsphere/features/cart/data/datasources/cart_data_sources.dart';
import 'package:shopsphere/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:shopsphere/features/cart/domain/repositories/cart_repository.dart';
import 'package:shopsphere/features/cart/domain/usecases/cart_usecases.dart';
import 'package:shopsphere/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:shopsphere/features/products/data/datasources/product_local_data_source.dart';
import 'package:shopsphere/features/products/data/datasources/product_remote_data_source.dart';
import 'package:shopsphere/features/products/data/repositories/product_repository_impl.dart';
import 'package:shopsphere/features/products/domain/repositories/product_repository.dart';
import 'package:shopsphere/features/products/domain/usecases/product_usecases.dart';
import 'package:shopsphere/features/products/presentation/bloc/categories_cubit.dart';
import 'package:shopsphere/features/products/presentation/bloc/product_details_cubit.dart';
import 'package:shopsphere/features/products/presentation/bloc/product_list_bloc.dart';
import 'package:shopsphere/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:shopsphere/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:shopsphere/features/profile/domain/repositories/profile_repository.dart';
import 'package:shopsphere/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:shopsphere/features/profile/presentation/bloc/profile_cubit.dart';

/// Global service locator. Widgets only ever resolve blocs/cubits from it;
/// they never construct repositories or data sources themselves.
final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // ---- External
  await Hive.initFlutter();
  final cartBox = await Hive.openBox<String>(CartLocalDataSourceImpl.boxName);
  final productsBox = await Hive.openBox<String>(
    ProductLocalDataSourceImpl.boxName,
  );
  final prefs = await SharedPreferences.getInstance();

  sl
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(),
    )
    ..registerLazySingleton<Connectivity>(Connectivity.new)
    // ---- Core
    ..registerLazySingleton<SessionManager>(SessionManager.new)
    ..registerLazySingleton<TokenStorage>(
      () => SecureTokenStorage(sl<FlutterSecureStorage>()),
    )
    ..registerLazySingleton<ApiClient>(
      () => ApiClient(
        buildDio(
          tokenStorage: sl<TokenStorage>(),
          sessionManager: sl<SessionManager>(),
        ),
      ),
    )
    // ---- Data sources
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<ProductRemoteDataSource>(
      () => ProductRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<ProductLocalDataSource>(
      () => ProductLocalDataSourceImpl(productsBox),
    )
    ..registerLazySingleton<CartLocalDataSource>(
      () => CartLocalDataSourceImpl(cartBox),
    )
    ..registerLazySingleton<CartRemoteDataSource>(
      () => CartRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSourceImpl(sl()),
    )
    // ---- Repositories
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remote: sl(), tokens: sl()),
    )
    ..registerLazySingleton<ProductRepository>(
      () => ProductRepositoryImpl(remote: sl(), local: sl()),
    )
    ..registerLazySingleton<CartRepository>(
      () => CartRepositoryImpl(local: sl(), remote: sl(), tokens: sl()),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(sl()),
    )
    // ---- Use cases
    ..registerLazySingleton(() => LoginUseCase(sl()))
    ..registerLazySingleton(() => CheckSessionUseCase(sl()))
    ..registerLazySingleton(() => LogoutUseCase(sl()))
    ..registerLazySingleton(() => GetProductsUseCase(sl()))
    ..registerLazySingleton(() => SearchProductsUseCase(sl()))
    ..registerLazySingleton(() => GetProductDetailsUseCase(sl()))
    ..registerLazySingleton(() => GetCategoriesUseCase(sl()))
    ..registerLazySingleton(() => LoadCartUseCase(sl()))
    ..registerLazySingleton(() => SaveCartUseCase(sl()))
    ..registerLazySingleton(() => PlaceOrderUseCase(sl()))
    ..registerLazySingleton(() => GetProfileUseCase(sl()))
    // ---- Blocs (app-wide singletons are created once in app.dart)
    ..registerFactory(
      () => AuthBloc(checkSession: sl(), logout: sl(), sessionManager: sl()),
    )
    ..registerFactory(
      () => CartBloc(loadCart: sl(), saveCart: sl(), placeOrder: sl()),
    )
    ..registerFactory(() => ThemeCubit(sl()))
    ..registerFactory(() => ConnectivityCubit(sl()))
    ..registerFactory(() => LoginCubit(sl()))
    ..registerFactory(
      () => ProductListBloc(getProducts: sl(), searchProducts: sl()),
    )
    ..registerFactory(() => CategoriesCubit(sl()))
    ..registerFactory(() => ProductDetailsCubit(sl()))
    ..registerFactory(() => ProfileCubit(sl()));
}
