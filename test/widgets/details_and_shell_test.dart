import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/app/app_shell.dart';
import 'package:shopsphere/core/di/injection.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/network/connectivity_cubit.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/cart/domain/entities/cart.dart';
import 'package:shopsphere/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:shopsphere/features/products/domain/entities/product.dart';
import 'package:shopsphere/features/products/presentation/bloc/categories_cubit.dart';
import 'package:shopsphere/features/products/presentation/bloc/product_details_cubit.dart';
import 'package:shopsphere/features/products/presentation/bloc/product_list_bloc.dart';
import 'package:shopsphere/features/products/presentation/pages/product_details_page.dart';
import 'package:shopsphere/features/profile/presentation/bloc/profile_cubit.dart';

import '../helpers/mocks.dart';
import '../helpers/pump.dart';

const _product = Product(
  id: 1,
  title: 'Essence Mascara Lash Princess',
  description: 'A popular mascara known for its volumizing effects.',
  category: 'beauty',
  price: 9.99,
  discountPercentage: 10.48,
  rating: 2.56,
  stock: 5,
  thumbnail: '',
  images: ['', ''],
  reviews: [
    Review(rating: 5, comment: 'Highly impressed!', reviewerName: 'Lucas'),
  ],
  shippingInformation: 'Ships in 3-5 business days',
);

void main() {
  late MockGetProductDetailsUseCase getDetails;
  late MockCartBloc cart;

  setUpAll(() => registerFallbackValue(const CartStarted()));

  setUp(() {
    getDetails = MockGetProductDetailsUseCase();
    cart = MockCartBloc();
    when(() => cart.state).thenReturn(const CartState(isLoaded: true));
    sl.registerFactory(() => ProductDetailsCubit(getDetails));
  });

  tearDown(sl.reset);

  Widget details(int id) => BlocProvider<CartBloc>.value(
    value: cart,
    child: ProductDetailsPage(productId: id),
  );

  group('ProductDetailsPage', () {
    for (final entry in allSizes.entries) {
      testWidgets('renders without overflow: ${entry.key} @ 1.3x', (
        tester,
      ) async {
        when(() => getDetails(1)).thenAnswer((_) async => const Ok(_product));
        await pumpAt(
          tester,
          details(1),
          size: entry.value,
          textScale: 1.3,
          scaffold: false,
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text(_product.title), findsOneWidget);
      });
    }

    testWidgets('shows price, brand-less fallback, reviews and adds to cart', (
      tester,
    ) async {
      when(() => getDetails(1)).thenAnswer((_) async => const Ok(_product));
      await pumpAt(tester, details(1), size: tabletPortrait, scaffold: false);
      await tester.pump();

      expect(find.text(r'$8.94'), findsOneWidget);
      expect(find.text('Only 5 left'), findsOneWidget);
      expect(find.text('Customer reviews (1)'), findsOneWidget);

      await tester.tap(find.byTooltip('Increase quantity'));
      await tester.pump();
      await tester.tap(find.text('Add to cart'));
      final added =
          verify(() => cart.add(captureAny())).captured.single as CartItemAdded;
      expect(added.item.productId, 1);
      expect(added.item.quantity, 2);
    });

    testWidgets('out of stock disables Add to cart', (tester) async {
      when(() => getDetails(1)).thenAnswer(
        (_) async =>
            const Ok(Product(id: 1, title: 'Gone', price: 1, thumbnail: '')),
      );
      await pumpAt(tester, details(1), scaffold: false);
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Out of stock').last,
          matching: find.byWidgetPredicate((w) => w is FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('a missing product shows the not-found state', (tester) async {
      when(() => getDetails(9999))
          .thenAnswer((_) async => const Err(NotFoundFailure()));
      await pumpAt(tester, details(9999), scaffold: false);
      await tester.pump();

      expect(
        find.text('This product does not exist or was removed.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsNothing);
    });
  });

  group('AppShell navigation', () {
    late MockConnectivityCubit connectivity;

    setUp(() {
      final listBloc = MockProductListBloc();
      final categories = MockCategoriesCubit();
      final profile = MockProfileCubit();
      connectivity = MockConnectivityCubit();
      when(() => listBloc.state).thenReturn(const ProductListState());
      when(() => categories.state).thenReturn(const CategoriesState());
      when(() => profile.state).thenReturn(const ProfileLoading());
      when(categories.load).thenAnswer((_) async {});
      when(profile.load).thenAnswer((_) async {});
      when(() => connectivity.state).thenReturn(false);
      when(() => cart.state).thenReturn(
        const CartState(
          isLoaded: true,
          totals: CartTotals(subtotal: 1, discount: 0, total: 1, itemCount: 3),
        ),
      );
      sl
        ..registerFactory<ProductListBloc>(() => listBloc)
        ..registerFactory<CategoriesCubit>(() => categories)
        ..registerFactory<ProfileCubit>(() => profile);
    });

    Widget shell() => MultiBlocProvider(
      providers: [
        BlocProvider<CartBloc>.value(value: cart),
        BlocProvider<ConnectivityCubit>.value(value: connectivity),
      ],
      child: const AppShell(),
    );

    testWidgets('phone: bottom navigation bar with a cart badge', (
      tester,
    ) async {
      await pumpAt(tester, shell(), scaffold: false);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('3'), findsWidgets); // badge count
    });

    testWidgets('tablet: navigation rail', (tester) async {
      await pumpAt(tester, shell(), size: tabletPortrait, scaffold: false);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('offline banner appears when connectivity drops', (
      tester,
    ) async {
      when(() => connectivity.state).thenReturn(true);
      await pumpAt(tester, shell(), scaffold: false);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('You are offline'), findsOneWidget);
    });
  });
}
