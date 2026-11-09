import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../services/downloader/downloader_config.dart';
import '../utils/url_launcher_helper.dart';
import '../widgets/main_shell.dart';
import '../widgets/responsive_layout.dart';

/// 在应用内打开下载器的 WebUI 页面
class DownloaderWebUiPage extends StatefulWidget {
  final QbittorrentConfig config;

  const DownloaderWebUiPage({super.key, required this.config});

  @override
  State<DownloaderWebUiPage> createState() => _DownloaderWebUiPageState();
}

class _DownloaderWebUiPageState extends State<DownloaderWebUiPage> {
  InAppWebViewController? _controller;
  bool _loading = true;
  String? _error;

  String get _url => widget.config.baseUrl;

  bool get _supportsInAppWebView {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final controller = _controller;
    if (controller == null) return;
    await controller.loadUrl(urlRequest: URLRequest(url: WebUri(_url)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_supportsInAppWebView,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        // 页面常驻在标签外壳里，只有正在显示时才能处理返回键
        final shell = MainShellController.instance;
        if (!shell.isActiveRoute('/downloader_webui')) return;

        final controller = _controller;
        if (controller != null) {
          try {
            if (await controller.canGoBack()) {
              await controller.goBack();
              return;
            }
          } catch (_) {}
        }

        if (shell.isAttached) {
          shell.openTab('/');
          return;
        }

        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: ResponsiveLayout(
        currentRoute: '/downloader_webui',
        appBar: AppBar(
          title: Text(widget.config.name),
          actions: [
            IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              tooltip: '刷新',
            ),
            IconButton(
              onPressed: () => UrlLauncherHelper.launchBrowser(context, _url),
              icon: const Icon(Icons.open_in_browser),
              tooltip: '在浏览器中打开',
            ),
          ],
        ),
        body: _supportsInAppWebView ? _buildWebView(context) : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.open_in_browser,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            '当前平台请使用系统浏览器访问',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => UrlLauncherHelper.launchBrowser(context, _url),
            icon: const Icon(Icons.launch),
            label: const Text('在浏览器中打开'),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (_error != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '网页加载失败',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_error\n$_url',
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _reload,
                    child: const Text('重试'),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_url)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              useOnDownloadStart: true,
              mediaPlaybackRequiresUserGesture: false,
            ),
            onWebViewCreated: (controller) => _controller = controller,
            onLoadStart: (controller, url) {
              if (!mounted) return;
              setState(() {
                _loading = true;
                _error = null;
              });
            },
            onLoadStop: (controller, url) {
              if (!mounted) return;
              setState(() => _loading = false);
            },
            onReceivedError: (controller, request, error) {
              if (!mounted || request.isForMainFrame == false) return;
              setState(() {
                _loading = false;
                _error = error.description;
              });
            },
          ),
        ),
      ],
    );
  }
}
