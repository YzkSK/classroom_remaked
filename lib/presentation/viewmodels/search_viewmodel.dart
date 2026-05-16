// lib/presentation/viewmodels/search_viewmodel.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/di/providers.dart';
import '../../domain/entities/assignment.dart';
part 'search_viewmodel.g.dart';

class SearchState {
  const SearchState({this.query = '', this.results = const []});
  final String query;
  final List<Assignment> results;
}

@riverpod
class SearchViewModel extends _$SearchViewModel {
  @override
  SearchState build() => const SearchState();

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const SearchState();
      return;
    }
    final rows = await ref.read(appDatabaseProvider).searchAssignments(query);
    state = SearchState(
      query: query,
      results: rows
          .map((r) => Assignment(
                id: r.id,
                courseId: r.courseId,
                title: r.title,
                description: r.description,
                dueDate: r.dueDateMillis != null
                    ? DateTime.fromMillisecondsSinceEpoch(r.dueDateMillis!)
                    : null,
              ))
          .toList(),
    );
  }

  void clear() => state = const SearchState();
}
