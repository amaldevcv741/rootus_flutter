import 'package:equatable/equatable.dart';
import '../data/product_model.dart';

abstract class ProductState extends Equatable {
  const ProductState();
  
  @override
  List<Object> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<ProductModel> products;
  final bool hasReachedMax;
  final int currentPage;

  const ProductLoaded({
    required this.products,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  ProductLoaded copyWith({
    List<ProductModel>? products,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return ProductLoaded(
      products: products ?? this.products,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object> get props => [products, hasReachedMax, currentPage];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object> get props => [message];
}
