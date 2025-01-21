import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/search/domain/repo/search_repo.dart';
import 'package:social/features/search/presentation/Cubits/search_states.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchRepo searchRepo;

  SearchCubit(this.searchRepo) : super(SearchInitialState());

  Future<void> searchusers(String query) async {
    if (query.isEmpty) {
      emit(SearchInitialState());
      return;
    }
    emit(SearchLoadingState());
    try {
      final users = await searchRepo.searchusers(query);
      emit(SearchLoadedState(users: users));
    } catch (e) {
      emit(SearchErrorState(message: e.toString()));
    }
  }
}
