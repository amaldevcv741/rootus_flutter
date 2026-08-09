import 'package:flutter_bloc/flutter_bloc.dart';
import 'product_event.dart';
import 'product_state.dart';
import '../data/product_repository.dart';
import '../../../../core/network/error_handler.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;

  ProductBloc({required this.repository}) : super(ProductInitial()) {
    on<FetchProducts>(_onFetchProducts);
    on<FetchMoreProducts>(_onFetchMoreProducts);
  }

  Future<void> _onFetchProducts(
    FetchProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    try {
      final products = await repository.getProducts(page: 1, limit: 10);
      emit(ProductLoaded(
        products: products,
        hasReachedMax: products.length < 10,
        currentPage: 1,
      ));
    } catch (e) {
      emit(ProductError(ErrorHandler.clean(e)));
    }
  }

  Future<void> _onFetchMoreProducts(
    FetchMoreProducts event,
    Emitter<ProductState> emit,
  ) async {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      if (currentState.hasReachedMax) return;

      try {
        final nextPage = currentState.currentPage + 1;
        final products = await repository.getProducts(page: nextPage, limit: 10);
        
        if (products.isEmpty) {
          emit(currentState.copyWith(hasReachedMax: true));
        } else {
          emit(currentState.copyWith(
            products: List.of(currentState.products)..addAll(products),
            hasReachedMax: products.length < 10,
            currentPage: nextPage,
          ));
        }
      } catch (e) {
        emit(ProductError(ErrorHandler.clean(e)));
      }
    }
  }
}
