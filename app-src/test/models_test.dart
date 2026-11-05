import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/core/models.dart';

void main() {
  group('backend envelope', () {
    test('unwraps data and reads rows / total', () {
      final j = <String, dynamic>{
        'code': 0,
        'data': <String, dynamic>{
          'list': <dynamic>[
            <String, dynamic>{'id': 'c1', 'name': '甲'}
          ],
          'total': 37,
        },
      };
      expect(rows(j).length, 1);
      expect(totalOf(j, 0), 37);
      expect(ComicSummary.fromJson(rows(j).first).title, '甲');
      expect(ComicSummary.fromJson(rows(j).first).id, 'c1');
    });

    test('tolerates an unwrapped response', () {
      final j = <String, dynamic>{
        'results': <dynamic>[
          <String, dynamic>{'uuid': 'n1', 'title': '乙'}
        ],
      };
      expect(rows(j).length, 1);
      expect(NovelSummary.fromJson(rows(j).first).id, 'n1');
    });
  });

  test('comic pages consume only server-provided URLs', () {
    final j = <String, dynamic>{
      'data': <String, dynamic>{
        'pages': <dynamic>[
          'https://cdn.example/1.jpg',
          <String, dynamic>{'url': 'https://cdn.example/2.jpg'},
        ],
      },
    };
    final p = ComicPages.fromJson(j, chapterId: 'ch1');
    expect(
      p.imageUrls,
      <String>[
        'https://cdn.example/1.jpg',
        'https://cdn.example/2.jpg',
      ],
    );
    expect(p.chapterId, 'ch1');
    expect(p.isEmpty, isFalse);
  });

  test('paged arithmetic', () {
    expect(
      const Paged<int>(items: <int>[], page: 1, total: 100, pageSize: 20)
          .hasMore,
      isTrue,
    );
    expect(
      const Paged<int>(items: <int>[], page: 5, total: 100, pageSize: 20)
          .hasMore,
      isFalse,
    );
  });
}
