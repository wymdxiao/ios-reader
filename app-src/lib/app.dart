import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/config.dart';
import 'core/session.dart';
import 'ui/home_shell.dart';
import 'ui/login_screen.dart';

class ReaderApp extends StatelessWidget {
  const ReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final cfg = AppConfig.current;
    final store = SessionStore.instance;
    final api = ApiClient(baseUrl: cfg.baseUrl, tokenProvider: store.token);
    return MaterialApp(
      title: 'Reader',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: cfg.configured ? AppGate(api: api) : const ConfigScreen(),
    );
  }
}

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('未配置服务地址')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.settings_ethernet, size: 40),
            SizedBox(height: 16),
            Text('构建时没有传入 API_BASE_URL。', style: TextStyle(fontSize: 16)),
            SizedBox(height: 12),
            Text('在 GitHub 仓库 Settings → Secrets and variables → Actions → '
                'Variables 里添加 API_BASE_URL，然后重新运行 workflow。'),
          ],
        ),
      ),
    );
  }
}

class AppGate extends StatefulWidget {
  const AppGate({super.key, required this.api});

  final ApiClient api;

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    SessionStore.instance.load().whenComplete(() {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ValueListenableBuilder<Session?>(
      valueListenable: SessionStore.instance,
      builder: (BuildContext context, Session? session, Widget? _) {
        if (session == null) return LoginScreen(api: widget.api);
        return HomeShell(api: widget.api);
      },
    );
  }
}
