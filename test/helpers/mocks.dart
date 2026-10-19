import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/network/api_client.dart';
import 'package:shopsphere/core/storage/token_storage.dart';
import 'package:shopsphere/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:shopsphere/features/auth/domain/repositories/auth_repository.dart';
import 'package:shopsphere/features/auth/domain/usecases/auth_usecases.dart';
import 'package:shopsphere/features/cart/data/datasources/cart_data_sources.dart';
import 'package:shopsphere/features/cart/domain/repositories/cart_repository.dart';
import 'package:shopsphere/features/cart/domain/usecases/cart_usecases.dart';
import 'package:shopsphere/features/products/data/datasources/product_local_data_source.dart';
import 'package:shopsphere/features/products/data/datasources/product_remote_data_source.dart';
import 'package:shopsphere/features/products/domain/repositories/product_repository.dart';
import 'package:shopsphere/features/products/domain/usecases/product_usecases.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockCheckSessionUseCase extends Mock implements CheckSessionUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockProductRemoteDataSource extends Mock
    implements ProductRemoteDataSource {}

class MockProductLocalDataSource extends Mock
    implements ProductLocalDataSource {}

class MockProductRepository extends Mock implements ProductRepository {}

class MockGetProductsUseCase extends Mock implements GetProductsUseCase {}

class MockSearchProductsUseCase extends Mock implements SearchProductsUseCase {}

class MockGetProductDetailsUseCase extends Mock
    implements GetProductDetailsUseCase {}

class MockCartLocalDataSource extends Mock implements CartLocalDataSource {}

class MockCartRemoteDataSource extends Mock implements CartRemoteDataSource {}

class MockCartRepository extends Mock implements CartRepository {}

class MockLoadCartUseCase extends Mock implements LoadCartUseCase {}

class MockSaveCartUseCase extends Mock implements SaveCartUseCase {}

class MockPlaceOrderUseCase extends Mock implements PlaceOrderUseCase {}
