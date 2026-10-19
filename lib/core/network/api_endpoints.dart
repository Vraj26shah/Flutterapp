/// All DummyJSON endpoints used by the app, in one place.
abstract final class ApiEndpoints {
  static const baseUrl = 'https://dummyjson.com';

  // Auth
  static const login = '/auth/login';
  static const me = '/auth/me';
  static const refresh = '/auth/refresh';

  // Products
  static const products = '/products';
  static const productSearch = '/products/search';
  static const categories = '/products/categories';
  static String product(int id) => '/products/$id';
  static String productsByCategory(String slug) => '/products/category/$slug';

  // Cart
  static const addCart = '/carts/add';

  /// Session length requested from the API, in minutes.
  static const tokenExpiryMins = 30;

  /// Lighter payload for list screens.
  static const productListFields =
      'title,price,discountPercentage,rating,thumbnail,stock,brand,category';
}
