import 'package:flutter/material.dart';

import '../pages/download_tasks_page.dart';
import '../pages/downloader_webui_page.dart';
import '../services/downloader/downloader_config.dart';

/// 主页 / 下载管理 / WebUI 三个常驻标签的切换控制。
///
/// 抽屉可能出现在被推入栈的页面（设置等）里，那里访问不到外壳的
/// InheritedWidget，所以用单例承载切换入口。
class MainShellController {
  MainShellController._();

  static final MainShellController instance = MainShellController._();

  static const List<String> tabs = ['/', '/download_tasks', '/downloader_webui'];

  final ValueNotifier<String> activeRoute = ValueNotifier<String>('/');

  void Function(String route, QbittorrentConfig? config)? _selectTab;

  bool get isAttached => _selectTab != null;

  void attach(void Function(String route, QbittorrentConfig? config)? selectTab) {
    _selectTab = selectTab;
  }

  void openTab(String route, {QbittorrentConfig? config}) {
    _selectTab?.call(route, config);
  }

  bool isActiveRoute(String route) =>
      !isAttached || activeRoute.value == route;
}

/// 承载常驻标签的外壳，首次进入某个标签时才创建对应页面，之后一直保留。
class MainShell extends StatefulWidget {
  final Widget home;

  const MainShell({super.key, required this.home});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final Set<String> _mountedTabs = {'/'};
  String _route = '/';
  QbittorrentConfig? _qbConfig;

  @override
  void initState() {
    super.initState();
    final controller = MainShellController.instance;
    controller.activeRoute.value = '/';
    controller.attach(_selectTab);
  }

  @override
  void dispose() {
    MainShellController.instance.attach(null);
    super.dispose();
  }

  void _selectTab(String route, QbittorrentConfig? config) {
    if (!mounted || !MainShellController.tabs.contains(route)) return;
    if (route == '/downloader_webui') {
      if (config == null && _qbConfig == null) return;
      _qbConfig = config ?? _qbConfig;
    }
    setState(() {
      _mountedTabs.add(route);
      _route = route;
    });
    MainShellController.instance.activeRoute.value = route;
  }

  Widget _buildTab(String route) {
    if (!_mountedTabs.contains(route)) return const SizedBox.shrink();
    switch (route) {
      case '/download_tasks':
        return const DownloadTasksPage();
      case '/downloader_webui':
        final config = _qbConfig!;
        return DownloaderWebUiPage(
          key: ValueKey('downloader_webui_${config.id}'),
          config: config,
        );
      default:
        return widget.home;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        if (_route != '/') {
          _selectTab('/', null);
        }
      },
      child: IndexedStack(
        index: MainShellController.tabs.indexOf(_route),
        children: [
          for (final route in MainShellController.tabs) _buildTab(route),
        ],
      ),
    );
  }
}
