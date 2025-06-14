import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

class BrowserPage extends StatefulWidget {
  final String url;
  final bool isShowAppBar;
  
  const BrowserPage({
    super.key,
    this.url = "https://www.baidu.com",
    this.isShowAppBar = true
  });

  @override
  _BrowserPageState createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage>
    with SingleTickerProviderStateMixin {
  late WebViewController _webViewController;
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = true;
  double _progress = 0;
  List<Map<String, String>> _bookmarks = [];
  List<Map<String, String>> _history = [];
  late TabController _tabController;
  bool _showBookmarks = false;
  bool _showHistory = false;
  final FocusNode _urlFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookmarks();
    _loadHistory();
    _initWebView();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // 添加以下配置以允许不安全内容
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
              _isLoading = _progress < 1;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _urlController.text = url;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });
            final title = await _webViewController.getTitle() ?? url;
            _addToHistory(url, title);
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
          },
          // 添加以下配置以允许不安全内容
          onUrlChange: (UrlChange change) {
            print('URL changed to: ${change.url}');
          },
        ),
      )
      // 添加以下配置以允许混合内容
      ..enableZoom(true)
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getString('bookmarks') ?? '[]';
    setState(() {
      _bookmarks = List<Map<String, String>>.from(
        json
            .decode(bookmarksJson)
            .map((item) => Map<String, String>.from(item)),
      );
    });
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bookmarks', json.encode(_bookmarks));
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('browser_history') ?? '[]';
    setState(() {
      _history = List<Map<String, String>>.from(
        json.decode(historyJson).map((item) => Map<String, String>.from(item)),
      );
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('browser_history', json.encode(_history));
  }

  void _addToHistory(String url, String title) {
    // 避免重复添加相同的URL
    final existingIndex = _history.indexWhere((item) => item['url'] == url);
    if (existingIndex != -1) {
      _history.removeAt(existingIndex);
    }

    _history.insert(0, {'url': url, 'title': title});

    // 限制历史记录数量
    if (_history.length > 100) {
      _history = _history.sublist(0, 100);
    }

    _saveHistory();
  }

  void _addBookmark() async {
    final currentUrl = await _webViewController.currentUrl();
    final title =
        await _webViewController.getTitle() ?? currentUrl ?? 'Bookmark';

    if (currentUrl != null) {
      // 检查是否已经存在相同URL的书签
      final existingIndex =
          _bookmarks.indexWhere((item) => item['url'] == currentUrl);
      if (existingIndex == -1) {
        setState(() {
          _bookmarks.add({'url': currentUrl, 'title': title});
        });
        _saveBookmarks();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已添加书签: $title')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('该网页已在书签中')),
        );
      }
    }
  }

  void _removeBookmark(int index) {
    setState(() {
      _bookmarks.removeAt(index);
    });
    _saveBookmarks();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已删除书签')),
    );
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除历史记录'),
        content: const Text('确定要清除所有浏览历史记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _history.clear();
              });
              _saveHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已清除所有历史记录')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _navigateToUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    try {
      final uri = Uri.parse(url);
      _webViewController.loadRequest(uri);
      setState(() {
        _showBookmarks = false;
        _showHistory = false;
      });
      _urlFocusNode.unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无效的URL: $url')),
      );
    }
  }

  void _searchOrNavigate(String text) {
    if (Uri.tryParse(text)?.hasScheme ?? false) {
      _navigateToUrl(text);
    } else if (text.contains('.') && !text.contains(' ')) {
      _navigateToUrl(text);
    } else {
      // 使用百度搜索
      final searchUrl =
          'https://www.baidu.com/s?wd=${Uri.encodeComponent(text)}';
      _navigateToUrl(searchUrl);
    }
  }

  Future<void> _downloadFile() async {
    try {
      final url = await _webViewController.currentUrl();
      if (url == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = url.split('/').last;
      final filePath = '${appDir.path}/$fileName';

      // 这里简化了下载逻辑，实际应用中可能需要更复杂的处理
      final response = await http.get(Uri.parse(url));
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('文件已下载到: $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下载失败: $e')),
      );
    }
  }

  // 在类的方法部分添加这个新方法
  Future<void> _applyDarkModeToWebView(bool darkMode) async {
    if (darkMode) {
      // 注入CSS使网页变为夜间模式
      await _webViewController.runJavaScript('''
        (function() {
          var style = document.createElement('style');
          style.id = 'dark-mode-style';
          style.innerHTML = `
            html, body { 
              background-color: #121212 !important; 
              color: #e0e0e0 !important;
            }
            a, h1, h2, h3, h4, h5, h6 { color: #bb86fc !important; }
            input, textarea, select { 
              background-color: #333 !important; 
              color: #fff !important; 
              border-color: #666 !important;
            }
            * { box-shadow: none !important; }
          `;
          document.head.appendChild(style);
        })();
      ''');
    } else {
      // 移除夜间模式CSS
      await _webViewController.runJavaScript('''
        (function() {
          var darkModeStyle = document.getElementById('dark-mode-style');
          if (darkModeStyle) {
            darkModeStyle.remove();
          }
        })();
      ''');
    }
  }

  // 添加一个新的状态变量来控制底部操作栏的展开状态
  bool _isBottomBarExpanded = false;
  // 添加状态变量跟踪当前模式
  bool _isDesktopMode = false;
  bool _isDarkMode = false;

  @override
  void dispose() {
    _urlController.dispose();
    _tabController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: widget.isShowAppBar ? AppBar(
          // titleSpacing: 0.0, // 将标题间距设为0
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          // 使用flexibleSpace来自定义AppBar的内部布局
          flexibleSpace: SafeArea(
            child: Row(
              children: [
                // 为返回按钮预留空间
                const SizedBox(width: 48),
                // 使用Expanded让搜索框占据剩余空间，并保留右侧间距
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0), // 保留右侧间距
                    child: Container(
                      height: 50,
                      margin: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: TextField(
                        controller: _urlController,
                        focusNode: _urlFocusNode,
                        decoration: InputDecoration(
                          hintText: '搜索或输入网址',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 10.0),
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _urlController.clear();
                            },
                          ),
                          isDense: true,
                          alignLabelWithHint: true,
                        ),
                        style: const TextStyle(fontSize: 16.0),
                        textAlignVertical: TextAlignVertical.center,
                        onSubmitted: _searchOrNavigate,
                        textInputAction: TextInputAction.go,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 使用空的title，因为我们已经在flexibleSpace中自定义了布局
          title: const SizedBox.shrink(),
        ) : null,
        body: Stack(
          children: [
            Column(
              children: [
                if (_isLoading)
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                Expanded(
                  child: WebViewWidget(controller: _webViewController),
                ),
              ],
            ),
            if (_showBookmarks)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '书签',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _showBookmarks = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _bookmarks.isEmpty
                            ? const Center(child: Text('没有书签'))
                            : ListView.builder(
                                itemCount: _bookmarks.length,
                                itemBuilder: (context, index) {
                                  final bookmark = _bookmarks[index];
                                  return ListTile(
                                    leading: const Icon(Icons.bookmark),
                                    title: Text(bookmark['title'] ?? ''),
                                    subtitle: Text(
                                      bookmark['url'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _removeBookmark(index),
                                    ),
                                    onTap: () {
                                      _navigateToUrl(bookmark['url'] ?? '');
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_showHistory)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '历史记录',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.delete_sweep),
                                  label: const Text('清除'),
                                  onPressed: _clearHistory,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _showHistory = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _history.isEmpty
                            ? const Center(child: Text('没有历史记录'))
                            : ListView.builder(
                                itemCount: _history.length,
                                itemBuilder: (context, index) {
                                  final historyItem = _history[index];
                                  return ListTile(
                                    leading: const Icon(Icons.history),
                                    title: Text(historyItem['title'] ?? ''),
                                    subtitle: Text(
                                      historyItem['url'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () {
                                      _navigateToUrl(historyItem['url'] ?? '');
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 展开的操作按钮区域
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isBottomBarExpanded ? 220 : 0, // 增加高度以容纳更多按钮
              child: _isBottomBarExpanded
                  ? Container(
                      color: Theme.of(context).bottomAppBarTheme.color ??
                          Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        mainAxisSpacing: 0,
                        crossAxisSpacing: 0,
                        children: [
                          _buildActionButton(
                              Icons.bookmark_add, '添加书签', () => _addBookmark()),
                          _buildActionButton(Icons.bookmark, '书签', () {
                            setState(() {
                              _showBookmarks = !_showBookmarks;
                              _showHistory = false;
                            });
                          }),
                          _buildActionButton(Icons.history, '历史', () {
                            setState(() {
                              _showHistory = !_showHistory;
                              _showBookmarks = false;
                            });
                          }),
                          _buildActionButton(
                              Icons.download, '下载', () => _downloadFile()),
                          _buildActionButton(Icons.share, '分享', () async {
                            final url = await _webViewController.currentUrl();
                            if (url != null) {
                              final title =
                                  await _webViewController.getTitle() ?? '网页';

                              // 使用share_plus插件实现系统分享
                              await Share.share(
                                '$title\n$url',
                                subject: title,
                              );
                            }
                          }),
                          _buildActionButton(
                              _isDesktopMode
                                  ? Icons.phone_android
                                  : Icons.desktop_mac,
                              _isDesktopMode ? '移动版' : '桌面版', () async {
                            final url = await _webViewController.currentUrl();
                            if (url != null) {
                              setState(() {
                                _isDesktopMode = !_isDesktopMode;
                              });

                              // 根据模式设置不同的User-Agent
                              if (_isDesktopMode) {
                                await _webViewController.setUserAgent(
                                    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('已切换到桌面版')),
                                );
                              } else {
                                await _webViewController.setUserAgent(
                                    'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('已切换到移动版')),
                                );
                              }

                              // 重新加载页面
                              _webViewController.reload();
                            }
                          }),
                          _buildActionButton(
                              _isDarkMode
                                  ? Icons.light_mode
                                  : Icons.nightlight_round,
                              _isDarkMode ? '浅色模式' : '夜间模式', () {
                            // 直接切换模式而不是显示对话框
                            setState(() {
                              _isDarkMode = !_isDarkMode;
                            });

                            _applyDarkModeToWebView(_isDarkMode);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '已切换到${_isDarkMode ? '深色' : '浅色'}模式')),
                            );
                          }),
                          _buildActionButton(Icons.settings, '设置', () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('浏览器设置'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.delete),
                                      title: const Text('清除历史记录'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _clearHistory();
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.info),
                                      title: const Text('关于浏览器'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        showAboutDialog(
                                          context: context,
                                          applicationName: '逸风浏览器',
                                          applicationVersion: '1.0.0',
                                          applicationIcon: const FlutterLogo(),
                                          children: [
                                            const Text(
                                                '一个简单的Flutter WebView浏览器'),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('关闭'),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // 底部主导航栏
            BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () async {
                      if (await _webViewController.canGoBack()) {
                        _webViewController.goBack();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已经是第一页了')),
                        );
                      }
                    },
                    tooltip: '后退',
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () async {
                      if (await _webViewController.canGoForward()) {
                        _webViewController.goForward();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已经是最后一页了')),
                        );
                      }
                    },
                    tooltip: '前进',
                  ),
                  IconButton(
                    icon: const Icon(Icons.home),
                    onPressed: () {
                      _webViewController.loadRequest(
                          Uri.parse('http://chuankuan.com.cn/weather'));
                    },
                    tooltip: '首页',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      _webViewController.reload();
                    },
                    tooltip: '刷新',
                  ),
                  IconButton(
                    icon: Icon(
                        _isBottomBarExpanded ? Icons.close : Icons.more_horiz),
                    onPressed: () {
                      setState(() {
                        _isBottomBarExpanded = !_isBottomBarExpanded;
                      });
                    },
                    tooltip: _isBottomBarExpanded ? '收起' : '更多操作',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      onWillPop: () async {
        if (await _webViewController.canGoBack()) {
          _webViewController.goBack();
          return false;
        }
        return true;
      },
    );
  }

  // 修改操作按钮样式，使其更美观
  Widget _buildActionButton(
      IconData icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 添加分享对话框方法
  // ignore: unused_element
  void _showShareDialog(String title, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('分享'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('标题: $title'),
            const SizedBox(height: 8),
            Text('链接: $url', style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // 尝试使用share_plus插件分享
                await Share.share(
                  '$title\n$url',
                  subject: title,
                );
                Navigator.pop(context);
              } catch (e) {
                // 如果分享失败，尝试使用剪贴板
                await _webViewController.runJavaScript('''
                  navigator.clipboard.writeText("$url").then(function() {
                    console.log('链接已复制到剪贴板');
                  })
                  .catch(function(error) {
                    console.error('复制失败: ', error);
                  });
                ''');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('链接已复制到剪贴板')),
                );
              }
            },
            child: const Text('分享链接'),
          ),
        ],
      ),
    );
  }
}
