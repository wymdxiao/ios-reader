/// Wire-format helpers and domain models.
///
/// The backend contract is deliberately loose: field names accept a few common
/// aliases so the client can be pointed at a self-hosted API without editing
/// every model. Only values actually returned by the server are consumed --
/// the client never derives, guesses or enumerates resource URLs.
typedef Json = Map<String, dynamic>;

String str(Object? v, [String fallback = '']) =>
    v == null ? fallback : v.toString();

int asInt(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

List<Json> asList(Object? v) {
  if (v is! List) return <Json>[];
  return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

List<String> asStrings(Object? v) {
  if (v is! List) return <String>[];
  final out = <String>[];
  for (final e in v) {
    if (e is String) {
      if (e.isNotEmpty) out.add(e);
    } else if (e is Map) {
      final u = e['url'] ?? e['image'] ?? e['src'] ?? e['path'];
      final s = str(u);
      if (s.isNotEmpty) out.add(s);
    }
  }
  return List<String>.unmodifiable(out);
}

Json payload(Json j) {
  final d = j['data'] ?? j['result'];
  if (d is Map) return Map<String, dynamic>.from(d);
  return j;
}

List<Json> rows(Json j) {
  final p = payload(j);
  final raw = p['list'] ??
      p['items'] ??
      p['results'] ??
      p['records'] ??
      j['list'] ??
      j['results'];
  return asList(raw);
}

int totalOf(Json j, int fallback) {
  final p = payload(j);
  return asInt(p['total'] ?? p['count'] ?? j['total'], fallback);
}

class Paged<T> {
  const Paged({
    required this.items,
    required this.page,
    required this.total,
    this.pageSize = 20,
  });

  final List<T> items;
  final int page;
  final int total;
  final int pageSize;

  bool get hasMore =>
      total <= 0 ? items.length >= pageSize : page * pageSize < total;
  bool get hasPrevious => page > 1;
}

class ComicSummary {
  const ComicSummary({
    required this.id,
    required this.title,
    this.cover = '',
    this.author = '',
    this.status = '',
  });

  final String id;
  final String title;
  final String cover;
  final String author;
  final String status;

  factory ComicSummary.fromJson(Json j) => ComicSummary(
        id: str(j['id'] ?? j['uuid'] ?? j['comic_id']),
        title: str(j['title'] ?? j['name'], '未命名'),
        cover: str(j['cover'] ?? j['cover_url'] ?? j['image'] ?? j['thumb']),
        author: str(j['author']),
        status: str(j['status']),
      );
}

class Chapter {
  const Chapter({required this.id, required this.title, this.order = 0});

  final String id;
  final String title;
  final int order;

  factory Chapter.fromJson(Json j, int index) => Chapter(
        id: str(j['id'] ?? j['uuid'] ?? j['chapter_id']),
        title: str(j['title'] ?? j['name'], '第 ${index + 1} 话'),
        order: asInt(j['order'] ?? j['index'], index),
      );
}

class ComicDetail {
  const ComicDetail({
    required this.title,
    required this.chapters,
    this.cover = '',
    this.description = '',
  });

  final String title;
  final String cover;
  final String description;
  final List<Chapter> chapters;

  factory ComicDetail.fromJson(Json j) {
    final p = payload(j);
    final raw = p['chapters'] ?? p['chapter_list'] ?? j['chapters'];
    final list = asList(raw)
        .asMap()
        .entries
        .map((e) => Chapter.fromJson(e.value, e.key))
        .toList();
    return ComicDetail(
      title: str(p['title'] ?? p['name'], '漫画'),
      cover: str(p['cover'] ?? p['cover_url'] ?? p['image']),
      description: str(p['description'] ?? p['intro'] ?? p['summary']),
      chapters: list,
    );
  }
}

class ComicPages {
  const ComicPages({required this.chapterId, required this.imageUrls});

  final String chapterId;
  final List<String> imageUrls;

  bool get isEmpty => imageUrls.isEmpty;

  factory ComicPages.fromJson(Json j, {String chapterId = ''}) {
    final p = payload(j);
    final raw = p['urls'] ?? p['pages'] ?? p['images'] ?? p['list'] ?? j['urls'];
    return ComicPages(
      chapterId: str(p['chapter_id'] ?? p['id'], chapterId),
      imageUrls: asStrings(raw),
    );
  }
}

class NovelSummary {
  const NovelSummary({
    required this.id,
    required this.title,
    this.cover = '',
    this.author = '',
  });

  final String id;
  final String title;
  final String cover;
  final String author;

  factory NovelSummary.fromJson(Json j) => NovelSummary(
        id: str(j['id'] ?? j['uuid'] ?? j['novel_id']),
        title: str(j['title'] ?? j['name'], '未命名'),
        cover: str(j['cover'] ?? j['cover_url'] ?? j['image']),
        author: str(j['author']),
      );
}

class NovelDetail {
  const NovelDetail({
    required this.title,
    required this.chapters,
    this.description = '',
  });

  final String title;
  final String description;
  final List<Chapter> chapters;

  factory NovelDetail.fromJson(Json j) {
    final p = payload(j);
    final raw = p['chapters'] ?? p['chapter_list'] ?? j['chapters'];
    final list = asList(raw)
        .asMap()
        .entries
        .map((e) => Chapter.fromJson(e.value, e.key))
        .toList();
    return NovelDetail(
      title: str(p['title'] ?? p['name'], '轻小说'),
      description: str(p['description'] ?? p['intro'] ?? p['summary']),
      chapters: list,
    );
  }
}

class NovelChapter {
  const NovelChapter({required this.title, required this.content});

  final String title;
  final String content;

  factory NovelChapter.fromJson(Json j) {
    final p = payload(j);
    return NovelChapter(
      title: str(p['title'] ?? p['name'], '正文'),
      content: str(p['content'] ?? p['text'] ?? p['body']),
    );
  }
}
