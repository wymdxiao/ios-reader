import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/models.dart';
import '../core/repositories.dart';
import 'common.dart';

class ComicListScreen extends StatefulWidget {
  const ComicListScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<ComicListScreen> createState() => _ComicListState();
}

class _ComicListState extends State<ComicListScreen> {
  final TextEditingController _search = TextEditingController();
  late Future<Paged<ComicSummary>> _future;
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
    _future = ComicRepository(widget.api).list(page: _page, query: _query);
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
      appBar: AppBar(title: const Text('漫画')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: _searchNow,
              decoration: const InputDecoration(
                hintText: '搜索漫画',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<Paged<ComicSummary>>(
              future: _future,
              builder: (BuildContext context,
                  AsyncSnapshot<Paged<ComicSummary>> snap) {
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
                    Paged<ComicSummary>(
                        items: const <ComicSummary>[], page: _page, total: 0);
                if (paged.items.isEmpty) {
                  return const Center(child: Text('没有数据'));
                }
                return ListView.separated(
                  itemCount: paged.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int i) {
                    final c = paged.items[i];
                    final sub = <String>[c.author, c.status]
                        .where((String s) => s.isNotEmpty)
                        .join(' · ');
                    return ListTile(
                      leading: c.cover.isEmpty
                          ? const Icon(Icons.photo_library_outlined)
                          : Image.network(
                              c.cover,
                              width: 48,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image_outlined),
                            ),
                      title: Text(c.title),
                      subtitle: sub.isEmpty ? null : Text(sub),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ComicDetailScreen(
                            api: widget.api,
                            comicId: c.id,
                            title: c.title,
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

class ComicDetailScreen extends StatefulWidget {
  const ComicDetailScreen({
    super.key,
    required this.api,
    required this.comicId,
    required this.title,
  });

  final ApiClient api;
  final String comicId;
  final String title;

  @override
  State<ComicDetailScreen> createState() => _ComicDetailState();
}

class _ComicDetailState extends State<ComicDetailScreen> {
  late Future<ComicDetail> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ComicRepository(widget.api).detail(widget.comicId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<ComicDetail>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<ComicDetail> snap) {
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
                                builder: (_) => ComicReaderScreen(
                                  api: widget.api,
                                  comicId: widget.comicId,
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

class ComicReaderScreen extends StatefulWidget {
  const ComicReaderScreen({
    super.key,
    required this.api,
    required this.comicId,
    required this.chapterId,
    required this.chapterTitle,
  });

  final ApiClient api;
  final String comicId;
  final String chapterId;
  final String chapterTitle;

  @override
  State<ComicReaderScreen> createState() => _ComicReaderState();
}

class _ComicReaderState extends State<ComicReaderScreen> {
  late Future<ComicPages> _future;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ComicRepository(widget.api)
        .pages(widget.comicId, widget.chapterId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chapterTitle)),
      body: FutureBuilder<ComicPages>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<ComicPages> snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return ErrorView(
              message: '${snap.error}',
              onRetry: () => setState(_load),
            );
          }
          final pages = snap.data;
          if (pages == null || pages.isEmpty) {
            return const Center(child: Text('本章没有可显示的页面'));
          }
          return Stack(
            children: <Widget>[
              PageView.builder(
                itemCount: pages.imageUrls.length,
                onPageChanged: (int i) => setState(() => _current = i),
                itemBuilder: (BuildContext context, int i) => InteractiveViewer(
                  child: Center(
                    child: Image.network(
                      pages.imageUrls[i],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image_outlined, size: 48),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_current + 1} / ${pages.imageUrls.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
