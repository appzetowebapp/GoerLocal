import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart' as dio;
import 'package:hyper_local_seller/config/global_keys.dart';
import 'package:hyper_local_seller/screen/more_page/view/brands/model/brands_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/brands/repo/brands_repo.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_controller.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';

part 'brands_event.dart';
part 'brands_state.dart';

class BrandsBloc extends Bloc<BrandsEvent, BrandsState> {
  final BrandsRepo _repo;
  late final PaginationController<Brand> _paginationController;

  String? _searchQuery;

  BrandsBloc(this._repo) : super(const BrandsState()) {
    _paginationController = PaginationController<Brand>(
      fetcher: _fetchBrands,
      emit: (state) => emit(state),
      perPage: GlobalKeys.perPage, // Increased to load more brands
    );

    on<LoadBrandsInitial>(_onLoadBrandsInitial);
    on<LoadMoreBrands>(_onLoadMoreBrands);
    on<RefreshBrands>(_onRefreshBrands);
    on<SearchBrands>(_onSearchBrands);
    on<AddBrandEvent>(_onAddBrand);
    on<ClearBrands>((event, emit) => emit(const BrandsState()));
  }

  Future<PaginationResponse<Brand>> _fetchBrands(int page, int perPage) async {
    final response = await _repo.getBrands(
      page: page,
      perPage: perPage,
      search: _searchQuery,
    );
    final brandsResponse = BrandsResponse.fromJson(response);
    
    return PaginationResponse(
      items: brandsResponse.data?.brands ?? [],
      total: brandsResponse.data?.total,
      currentPage: page,
    );
  }

  Future<void> _onLoadBrandsInitial(
    LoadBrandsInitial event,
    Emitter<BrandsState> emit,
  ) async {
    _searchQuery = event.search;
    // Always load initial if search is null (resetting) or state is empty
    if (state.items.isEmpty || _searchQuery == null || _searchQuery != null) {
      await _paginationController.loadInitial();
    }
  }

  Future<void> _onSearchBrands(
    SearchBrands event,
    Emitter<BrandsState> emit,
  ) async {
    _searchQuery = event.query;
    await _paginationController.loadInitial();
  }

  Future<void> _onLoadMoreBrands(
    LoadMoreBrands event,
    Emitter<BrandsState> emit,
  ) async {
    await _paginationController.loadNextPage(state);
  }

  Future<void> _onRefreshBrands(
    RefreshBrands event,
    Emitter<BrandsState> emit,
  ) async {
    await _paginationController.refresh(state);
  }

  Future<void> _onAddBrand(
    AddBrandEvent event,
    Emitter<BrandsState> emit,
  ) async {
    try {
      emit(state.copyWith(
        isInitialLoading: true,
        clearOperation: true,
      ));

      final formData = dio.FormData.fromMap({
        'title': event.title,
        'description': event.description,
        'status': event.status,
        'logo': await dio.MultipartFile.fromFile(
          event.imagePath,
          filename: event.imagePath.split('/').last,
        ),
      });

      await _repo.addBrand(formData);

      emit(state.copyWith(
        isInitialLoading: false,
        operationSuccess: true,
        operationMessage: 'Brand added successfully',
        lastOperationType: 'add',
      ));

      add(RefreshBrands());
    } catch (e) {
      emit(state.copyWith(
        isInitialLoading: false,
        operationSuccess: false,
        operationMessage: e.toString(),
        lastOperationType: 'add',
      ));
    }
  }
}

