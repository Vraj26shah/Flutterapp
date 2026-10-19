import 'package:equatable/equatable.dart';

class Review extends Equatable {
  const Review({
    required this.rating,
    required this.comment,
    required this.reviewerName,
    this.date,
  });

  final int rating;
  final String comment;
  final String reviewerName;
  final DateTime? date;

  @override
  List<Object?> get props => [rating, comment, reviewerName, date];
}

class Product extends Equatable {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.thumbnail,
    this.description = '',
    this.category = '',
    this.discountPercentage = 0,
    this.rating = 0,
    this.stock = 0,
    this.brand,
    this.images = const [],
    this.reviews = const [],
    this.availabilityStatus,
    this.warrantyInformation,
    this.shippingInformation,
    this.returnPolicy,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;

  /// Absent on ~half of DummyJSON products.
  final String? brand;
  final String thumbnail;
  final List<String> images;
  final List<Review> reviews;
  final String? availabilityStatus;
  final String? warrantyInformation;
  final String? shippingInformation;
  final String? returnPolicy;

  bool get isInStock => stock > 0;
  bool get isLowStock => stock > 0 && stock < 10;
  bool get hasDiscount => discountPercentage > 0;

  /// Price after discount, rounded to cents.
  double get finalPrice =>
      (price * (1 - discountPercentage / 100) * 100).roundToDouble() / 100;

  /// Images for the gallery, falling back to the thumbnail.
  List<String> get gallery => images.isNotEmpty ? images : [thumbnail];

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    price,
    discountPercentage,
    rating,
    stock,
    brand,
    thumbnail,
    images,
    reviews,
    availabilityStatus,
  ];
}
