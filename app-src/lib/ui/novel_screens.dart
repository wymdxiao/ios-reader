import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/models.dart';
import '../core/repositories.dart';
import 'common.dart';

class NovelListScreen extends StatefulWidget {
  const NovelListScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<NovelListScreen> createState() => _NovelListState();
}

class _NovelListState extends State<NovelListScreen> {
  final TextEditingController _search = TextEditingController();
  late Future<Paged<NovelSummary>> _future;
  int _page = 1;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    _future = NovelRepository(widget.api).list(page: _page, query: _query);
  }

  void _go(int page) {
    setState(() {
      _page = page;
      _reload();
    });
  }

  void _searchNow(String q) {
    setState(() {
      _query = q.trim();
      _page = 1;
      _reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('轻小说')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: _searchNow,
              decoration: const InputDecoration(
                hintText: '搜索轻小说',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<Paged<NovelSummary>>(
              future: _future,
              builder: (BuildContext context,
                  AsyncSnapshot<Paged<NovelSummary>> snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const LoadingView();
                }
                if (snap.hasError) {
                  return ErrorView(
                    message: '${snap.error}',
                    onRetry: () => setState(_reload),
                  );
                }
                final paged = snap.data ??
                    Paged<NovelSummary>(
                        items: const <NovelSummary>[], page: _page, total: 0);
                if (paged.items.isEmpty) {
                  return const Center(child: Text('没有数据'));
                }
                return ListView.separated(
                  itemCount: paged.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int i) {
                    final n = paged.items[i];
                    return ListTile(
                      leading: n.cover.isEmpty
                          ? const Icon(Icons.menu_book_outlined)
                          : Image.network(
                              n.cover,
                              width: 48,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image_outlined),
                            ),
                      title: Text(n.title),
                      subtitle: n.author.isEmpty ? null : Text(n.author),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => NovelDetailScreen(
                            api: widget.api,
                            novelId: n.id,
                            title: n.title,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('第 $_page 页'),
                Row(
                  children: <Widget>[
                    IconButton(
                      tooltip: '上一页',
                      onPressed: _page > 1 ? () => _go(_page - 1) : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      tooltip: '下一页',
                      onPressed: () => _go(_page + 1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NovelDetailScreen extends StatefulWidget {
  const NovelDetailScreen({
    super.key,
    required this.api,
    required this.novelId,
    required this.title,
  });

  final ApiClient api;
  final String novelId;
  final String title;

  @override
  State<NovelDetailScreen> createState() => _NovelDetailState();
}

class _NovelDetailState extends State<NovelDetailScreen> {
  late Future<NovelDetail> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = NovelRepository(widget.api).detail(widget.novelId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<NovelDetail>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<NovelDetail> snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return ErrorView(
              message: '${snap.error}',
              onRetry: () => setState(_load),
            );
          }
          final d = snap.data;
          if (d == null) return const Center(child: Text('没有数据'));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (d.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(d.description),
                ),
              const Divider(height: 1),
              Expanded(
                child: d.chapters.isEmpty
                    ? const Center(child: Text('暂无章节'))
                    : ListView.builder(
                        itemCount: d.chapters.length,
                        itemBuilder: (BuildContext context, int i) {
                          final ch = d.chapters[i];
                          return ListTile(
                            leading: CircleAvatar(child: Text('${i + 1}')),
                            title: Text(ch.title),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => NovelReadScreen(
                                  api: widget.api,
                                  novelId: widget.novelId,
                                  chapterId: ch.id,
                                  chapterTitle: ch.title,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class NovelReadScreen extends StatefulWidget {
  const NovelReadScreen({
    super.key,
    required this.api,
    required this.novelId,
    required this.chapterId,
    required this.chapterTitle,
  });

  final ApiClient api;
  final String novelId;
  final String chapterId;
  final String chapterTitle;

  @override
  State<NovelReadScreen> createState() => _NovelReadState();
}

class _NovelReadState extends State<NovelReadScreen> {
  late Future<NovelChapter> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = NovelRepository(widget.api)
        .chapter(widget.novelId, widget.chapterId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chapterTitle)),
      body: FutureBuilder<NovelChapter>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<NovelChapter> snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return ErrorView(
              message: '${snap.error}',
              onRetry: () => setState(_load),
            );
          }
          final ch = snap.data;
          if (ch == null || ch.content.isEmpty) {
            return const Center(child: Text('本章没有正文'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(
              ch.content,
              style: const TextStyle(fontSize: 17, height: 1.8),
            ),
          );
        },
      ),
    );
  }
}
