import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/features/auth/data/models/user_model.dart';
import 'package:shopsphere/features/cart/data/models/cart_item_model.dart';

import '../../../helpers/fixture_reader.dart';

void main() {
  test('LoginResponseModel parses tokens and user', () {
    final response = LoginResponseModel.fromJson(fixtureMap('login.json'));

    expect(response.accessToken, 'test-access-token');
    expect(response.refreshToken, 'test-refresh-token');
    expect(response.user.id, 1);
    expect(response.user.username, 'emilys');
    expect(response.user.fullName, 'Emily Johnson');
    expect(response.user.phone, isNull); // login payload has no phone
  });

  test('OrderConfirmationModel parses POST /carts/add', () {
    final order = OrderConfirmationModel.fromJson(fixtureMap('cart_add.json'));

    expect(order.totalProducts, 1);
    expect(order.totalQuantity, 2);
    expect(order.total, 89.98);
  });
}
