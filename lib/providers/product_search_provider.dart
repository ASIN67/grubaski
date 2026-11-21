import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food_product.dart';
import '../repositories/product_repository.dart';
import '../services/open_food_facts_service.dart';

final openFoodFactsServiceProvider = Provider<OpenFoodFactsService>((ref) {
  return OpenFoodFactsService();
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(
    openFoodFactsService: ref.watch(openFoodFactsServiceProvider),
  );
});

final localProductsProvider = Provider<List<FoodProduct>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  final subscription =
      repository.productChanges.listen((_) => ref.invalidateSelf());
  ref.onDispose(subscription.cancel);
  return repository.getAllLocalProducts();
});

class ProductSearchState {
  final String query;
  final bool isLoading;
  final List<FoodProduct> results;
  final String? errorMessage;

  const ProductSearchState({
    this.query = '',
    this.isLoading = false,
    this.results = const [],
    this.errorMessage,
  });
}

class ProductSearchNotifier extends StateNotifier<ProductSearchState> {
  final ProductRepository _repository;
  final OpenFoodFactsService _remoteService;
  Timer? _debounce;
  CancelToken? _request;
  List<String> _remoteIds = const [];

  ProductSearchNotifier(this._repository, this._remoteService)
      : super(ProductSearchState(results: _repository.getAllLocalProducts()));

  void onQueryChanged(String input) {
    _setQuery(input);
    if (state.isLoading) {
      _debounce = Timer(const Duration(milliseconds: 500), _searchRemote);
    }
  }

  void searchImmediate(String input) {
    _setQuery(input);
    if (state.isLoading) unawaited(_searchRemote());
  }

  void _setQuery(String input) {
    _debounce?.cancel();
    _request?.cancel();
    _remoteIds = const [];
    final query = input.trim();
    state = ProductSearchState(
      query: query,
      isLoading: query.length >= 2,
      results: _repository.searchLocalProducts(query),
    );
  }

  void refreshLocalResults() {
    _publish(isLoading: state.isLoading, error: state.errorMessage);
  }

  void _publish({bool isLoading = false, String? error}) {
    final query = state.query;
    final results = {
      for (final product in _repository.searchLocalProducts(query))
        product.id: product,
    };
    for (final id in _remoteIds) {
      final product = _repository.getProductById(id);
      if (product != null) results[id] = product;
    }
    state = ProductSearchState(
      query: query,
      isLoading: isLoading,
      results: results.values.toList(),
      errorMessage: error,
    );
  }

  Future<void> _searchRemote() async {
    final request = CancelToken();
    _request = request;
    try {
      final remoteResults = await _remoteService.searchProducts(
        state.query,
        cancelToken: request,
        pageSize: 30,
      );
      if (request.isCancelled) return;
      final cached = await _repository.cacheRemoteProducts(remoteResults);
      if (request.isCancelled) return;
      _remoteIds = cached.map((product) => product.id).toList();
      _publish();
    } catch (error) {
      if (request.isCancelled) return;
      debugPrint('Product search failed: $error');
      _publish(error: 'Nie udało się pobrać produktów online.');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _request?.cancel();
    super.dispose();
  }
}

/// Each catalog screen has an independent search field and remote request.
final productSearchProvider = StateNotifierProvider.autoDispose
    .family<ProductSearchNotifier, ProductSearchState, Object>((ref, scope) {
  final notifier = ProductSearchNotifier(
    ref.watch(productRepositoryProvider),
    ref.watch(openFoodFactsServiceProvider),
  );
  ref.listen(localProductsProvider, (_, __) => notifier.refreshLocalResults());
  return notifier;
});
