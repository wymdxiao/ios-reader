import 'api_client.dart';
import 'models.dart';
import 'session.dart';

/// API contract for the three features. Paths and field names here are the
/// client-side contract; adjust them to match the backend you control.
///
/// GET  /comics?page=&q=                          -> list
/// GET  /comics/:id                              -> detail + chapters
/// GET  /comics/:id/chapters/:chapterId          -> image URL list
/// GET  /novels?page=&q=                         -> list
/// GET  /novels/:id                              -> detail + chapters
/// GET  /novels/:id/chapters/:chapterId          -> text content
/// POST /auth/login  {username, password}        -> {token}
class AuthRepository {
  const AuthRepository(this._api);

  final ApiClient _api;

  Future<Session> login(String username, String password) async {
    final j = await _api.post(
      '/auth/login',
      body: <String, dynamic>{'username': username, 'password': password},
    );
    final p = payload(j);
    final token = str(p['token'] ?? p['access_token'] ?? p['jwt']);
    if (token.isEmpty) {
      throw const ApiException(200, '登录响应里没有 token，请检查后端契约');
    }
    return Session(
      token: token,
      displayName: str(p['nickname'] ?? p['username'], username),
    );
  }
}

class ComicRepository {
  const ComicRepository(this._api);

  final ApiClient _api;

  Future<Paged<ComicSummary>> list({int page = 1, String query = ''}) async {
    final j = await _api.get(
      '/comics',
      query: <String, String>{
        'page': '$page',
        if (query.isNotEmpty) 'q': query,
      },
    );
    final items = rows(j).map(ComicSummary.fromJson).toList();
    return Paged<ComicSummary>(
      items: items,
      page: page,
      total: totalOf(j, items.length),
    );
  }

  Future<ComicDetail> detail(String id) async {
    final j = await _api.get('/comics/${Uri.encodeComponent(id)}');
    return ComicDetail.fromJson(j);
  }

  /// Reads only the URL list the server returned for this chapter.
  Future<ComicPages> pages(String comicId, String chapterId) async {
    final j = await _api.get(
      '/comics/${Uri.encodeComponent(comicId)}'
      '/chapters/${Uri.encodeComponent(chapterId)}',
    );
    return ComicPages.fromJson(j, chapterId: chapterId);
  }
}

class NovelRepository {
  const NovelRepository(this._api);

  final ApiClient _api;

  Future<Paged<NovelSummary>> list({int page = 1, String query = ''}) async {
    final j = await _api.get(
      '/novels',
      query: <String, String>{
        'page': '$page',
        if (query.isNotEmpty) 'q': query,
      },
    );
    final items = rows(j).map(NovelSummary.fromJson).toList();
    return Paged<NovelSummary>(
      items: items,
      page: page,
      total: totalOf(j, items.length),
    );
  }

  Future<NovelDetail> detail(String id) async {
    final j = await _api.get('/novels/${Uri.encodeComponent(id)}');
    return NovelDetail.fromJson(j);
  }

  Future<NovelChapter> chapter(String novelId, String chapterId) async {
    final j = await _api.get(
      '/novels/${Uri.encodeComponent(novelId)}'
      '/chapters/${Uri.encodeComponent(chapterId)}',
    );
    return NovelChapter.fromJson(j);
  }
}
