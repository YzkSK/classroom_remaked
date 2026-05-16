// lib/presentation/views/search/search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../domain/entities/assignment.dart';
import '../../viewmodels/search_viewmodel.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchViewModelProvider);
    final notifier = ref.read(searchViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('検索')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ShadInput(
              controller: _controller,
              placeholder: const Text('課題名で検索...'),
              leading: const Icon(Icons.search, size: 16),
              trailing: state.query.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _controller.clear();
                        notifier.clear();
                      },
                      child: const Icon(Icons.close, size: 16),
                    )
                  : null,
              onChanged: (q) => notifier.search(q),
            ),
          ),
          Expanded(
            child: state.query.isEmpty
                ? const Center(child: Text('キーワードを入力してください'))
                : state.results.isEmpty
                    ? Center(child: Text('「${state.query}」に一致する課題はありません'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.results.length,
                        itemBuilder: (context, index) =>
                            _ResultCard(assignment: state.results[index]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.assignment});

  final Assignment assignment;

  @override
  Widget build(BuildContext context) {
    final due = assignment.dueDate;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShadCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(assignment.title,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              if (due != null)
                Text(
                  '締め切り: ${DateFormat('yyyy/M/d HH:mm').format(due)}',
                  style: ShadTheme.of(context).textTheme.muted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
