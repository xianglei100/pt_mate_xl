import 'package:flutter/material.dart';

import '../pages/download_tasks_page.dart';
import '../pages/server_settings_page.dart';
import '../pages/settings_page.dart';
import '../pages/about_page.dart';
import '../pages/downloader_webui_page.dart';
import '../services/downloader/downloader_config.dart';
import '../services/storage/storage_service.dart';
import '../utils/notification_helper.dart';
import '../app.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback? onSettingsChanged;
  final String? currentRoute;
  final bool isFixedSidebar;

  const AppDrawer({
    super.key,
    this.onSettingsChanged,
    this.currentRoute,
    this.isFixedSidebar = false,
  });

  /// 直接在应用内打开默认 qBittorrent 下载器的 WebUI
  Future<void> _openQbWebUi(BuildContext context) async {
    final navigator = Navigator.of(context);

    final List<QbittorrentConfig> qbClients;
    final String? defaultId;
    try {
      final configs = await StorageService.instance.loadDownloaderConfigs();
      defaultId = await StorageService.instance.loadDefaultDownloaderId();
      qbClients = configs
          .map((data) => DownloaderConfig.fromJson(data))
          .whereType<QbittorrentConfig>()
          .toList();
    } catch (e) {
      if (context.mounted) {
        NotificationHelper.showError(context, '读取下载器配置失败：$e');
      }
      return;
    }

    if (!context.mounted) return;
    if (qbClients.isEmpty) {
      NotificationHelper.showError(context, '还没有配置 qBittorrent 下载器');
      return;
    }

    final config = qbClients.firstWhere(
      (c) => c.id == defaultId,
      orElse: () => qbClients.first,
    );

    if (!isFixedSidebar) {
      navigator.pop();
    }
    if (isFixedSidebar) {
      navigator.pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) =>
              DownloaderWebUiPage(config: config),
          settings: const RouteSettings(name: '/downloader_webui'),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => DownloaderWebUiPage(config: config),
          settings: const RouteSettings(name: '/downloader_webui'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final drawerHeaderBackground = !isFixedSidebar
        ? (isDark ? colorScheme.primaryContainer : colorScheme.primary)
        : colorScheme.surface;
    final drawerHeaderForeground = !isFixedSidebar
        ? (isDark ? colorScheme.onPrimaryContainer : colorScheme.onPrimary)
        : colorScheme.onSurface;

    final drawerContent = Material(
      color: colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero, // 移除默认的 padding，让 DrawerHeader 能够延伸到状态栏
        children: [
          // 只在非固定菜单模式下显示 header
          if (!isFixedSidebar)
            DrawerHeader(
              decoration: BoxDecoration(color: drawerHeaderBackground),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'PT Mate',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: drawerHeaderForeground,
                  ),
                ),
              ),
            ),
          // 固定菜单模式下添加一些顶部间距
          if (isFixedSidebar) const SizedBox(height: 16),
          _DrawerItem(
            icon: Icons.home_outlined,
            title: '主页',
            isActive: currentRoute == '/home' || currentRoute == '/',
            onTap: () {
              if (!isFixedSidebar) {
                Navigator.of(context).pop();
              }
              // 如果不在主页，导航到主页
              if (currentRoute != '/home' && currentRoute != '/') {
                if (isFixedSidebar) {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) =>
                          const HomePage(),
                      settings: const RouteSettings(name: '/'),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                } else {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const HomePage(),
                      settings: const RouteSettings(name: '/'),
                    ),
                    (route) => false,
                  );
                }
              }
            },
          ),
          _DrawerItem(
            icon: Icons.download_outlined,
            title: '下载管理',
            isActive: currentRoute == '/download_tasks',
            onTap: () {
              if (!isFixedSidebar) {
                Navigator.of(context).pop();
              }
              if (currentRoute != '/download_tasks') {
                if (isFixedSidebar) {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) =>
                          const DownloadTasksPage(),
                      settings: const RouteSettings(name: '/download_tasks'),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DownloadTasksPage(),
                      settings: const RouteSettings(name: '/download_tasks'),
                    ),
                  );
                }
              }
            },
          ),
          _DrawerItem(
            icon: Icons.web_asset,
            title: 'qBittorrent WebUI',
            isActive: currentRoute == '/downloader_webui',
            onTap: () => _openQbWebUi(context),
          ),
          _DrawerItem(
            icon: Icons.dns,
            title: '站点配置',
            isActive: currentRoute == '/server_settings',
            onTap: () {
              if (!isFixedSidebar) {
                Navigator.of(context).pop();
              }
              if (currentRoute != '/server_settings') {
                if (isFixedSidebar) {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) =>
                          const ServerSettingsPage(),
                      settings: const RouteSettings(name: '/server_settings'),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ServerSettingsPage(),
                      settings: const RouteSettings(name: '/server_settings'),
                    ),
                  );
                }
              }
            },
          ),
          _DrawerItem(
            icon: Icons.settings_outlined,
            title: '设置',
            isActive: currentRoute == '/settings',
            onTap: () async {
              if (!isFixedSidebar) {
                Navigator.of(context).pop();
              }
              if (currentRoute != '/settings') {
                if (isFixedSidebar) {
                  await Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) =>
                          const SettingsPage(),
                      settings: const RouteSettings(name: '/settings'),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                } else {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsPage(),
                      settings: const RouteSettings(name: '/settings'),
                    ),
                  );
                  // 从设置页面返回后，重新加载分类配置
                  onSettingsChanged?.call();
                }
              }
            },
          ),
          _DrawerItem(
            icon: Icons.info_outline,
            title: '关于',
            isActive: currentRoute == '/about',
            onTap: () {
              if (!isFixedSidebar) {
                Navigator.of(context).pop();
              }
              if (currentRoute != '/about') {
                if (isFixedSidebar) {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) =>
                          const AboutPage(),
                      settings: const RouteSettings(name: '/about'),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AboutPage(),
                      settings: const RouteSettings(name: '/about'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );

    // 根据 isFixedSidebar 参数决定返回 Drawer 还是直接返回内容
    if (isFixedSidebar) {
      return drawerContent;
    } else {
      return Drawer(child: drawerContent);
    }
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isActive ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          selected: isActive,
          selectedColor: colorScheme.onPrimaryContainer,
          iconColor: colorScheme.onSurfaceVariant,
          textColor: colorScheme.onSurface,
          leading: Icon(
            icon,
            color: isActive ? colorScheme.onPrimaryContainer : null,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? colorScheme.onPrimaryContainer : null,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
