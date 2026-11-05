import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/session.dart';
import 'comic_screens.dart';
import 'novel_screens.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.api});

  final ApiClient api;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      ComicListScreen(api: widget.api),
      NovelListScreen(api: widget.api),
      const AccountScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) => setState(() => _index = i),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: '漫画',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: '轻小说',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ValueListenableBuilder<Session?>(
        valueListenable: SessionStore.instance,
        builder: (BuildContext context, Session? session, Widget? _) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.account_circle_outlined, size: 56),
                const SizedBox(height: 12),
                Text(session?.displayName ?? '未登录'),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: () => SessionStore.instance.clear(),
                  child: const Text('退出登录'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
