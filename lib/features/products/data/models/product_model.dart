import 'package:shopsphere/features/products/domain/entities/product.dart';
import 'package:shopsphere/features/products/domain/entities/product_query.dart';

double _toDouble(Object? v) => (v as num?)?.toDouble() ?? 0;

class ReviewModel extends Review {
  const ReviewModel({
    required super.rating,
    required super.comment,
    required super.reviewerName,
    super.date,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    rating: (json['rating'] as num?)?.toInt() ?? 0,
    comment: json['comment'] as String? ?? '',
    reviewerName: json['reviewerName'] as String? ?? 'Anonymous',
    date: DateTime.tryParse(json['date'] as String? ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'rating': rating,
    'comment': comment,
    'reviewerName': reviewerName,
    'date': date?.toIso8601String(),
  };
}

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.title,
    required super.price,
    required super.thumbnail,
    super.description,
    super.category,
    super.discountPercentage,
    super.rating,
    super.stock,
    super.brand,
    super.images,
    super.reviews,
    super.availabilityStatus,
    super.warrantyInformation,
    super.shippingInformation,
    super.returnPolicy,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: (json['id'] as num).toInt(),
    title: json['title'] as String? ?? 'Untitled',
    description: json['description'] as String? ?? '',
    category: json['category'] as String? ?? '',
    price: _toDouble(json['price']),
    discountPercentage: _toDouble(json['discountPercentage']),
    rating: _toDouble(json['rating']),
    stock: (json['stock'] as num?)?.toInt() ?? 0,
    brand: json['brand'] as String?,
    thumbnail: json['thumbnail'] as String? ?? '',
    images: (json['images'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false),
    reviews: (json['reviews'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ReviewModel.fromJson)
        .toList(growable: false),
    availabilityStatus: json['availabilityStatus'] as String?,
    warrantyInformation: json['warrantyInformation'] as String?,
    shippingInformation: json['shippingInformation'] as String?,
    returnPolicy: json['returnPolicy'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'price': price,
    'discountPercentage': discountPercentage,
    'rating': rating,
    'stock': stock,
    'brand': brand,
    'thumbnail': thumbnail,
    'images': images,
    'reviews': [
      for (final r in reviews)
        ReviewModel(
          rating: r.rating,
          comment: r.comment,
          reviewerName: r.reviewerName,
          date: r.date,
        ).toJson(),
    ],
    'availabilityStatus': availabilityStatus,
  };
}

class ProductPageModel extends ProductPage {
  const ProductPageModel({
    required super.products,
    required super.total,
    required super.skip,
    required super.limit,
    super.isFromCache,
  });

  factory ProductPageModel.fromJson(
    Map<String, dynamic> json, {
    bool isFromCache = false,
  }) => ProductPageModel(
    products: (json['products'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList(growable: false),
    total: (json['total'] as num?)?.toInt() ?? 0,
    skip: (json['skip'] as num?)?.toInt() ?? 0,
    limit: (json['limit'] as num?)?.toInt() ?? 0,
    isFromCache: isFromCache,
  );

  Map<String, dynamic> toJson() => {
    'products': [for (final p in products) (p as ProductModel).toJson()],
    'total': total,
    'skip': skip,
    'limit': limit,
  };
}

class CategoryModel extends Category {
  const CategoryModel({required super.slug, required super.name});

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    slug: json['slug'] as String,
    name: json['name'] as String? ?? json['slug'] as String,
  );

  Map<String, dynamic> toJson() => {'slug': slug, 'name': name};
}
