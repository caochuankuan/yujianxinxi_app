import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yifeng_site/views/main_page.dart';
import 'package:yifeng_site/views/news/daily_news_page.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:device_preview_screenshot/device_preview_screenshot.dart';

void main() {
  runApp(const YujianInfo());
}

class YujianInfo extends StatefulWidget {
  const YujianInfo({super.key});

  @override
  _YujianInfoState createState() => _YujianInfoState();
}

class _YujianInfoState extends State<YujianInfo> {
  bool _isDarkMode = false; // 夜间模式
  bool useDevicePreview = false; // 设备预览开关
  String shortcut = 'no action set';
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool isBlurEnabled = false; // 高斯模糊

  @override
  void initState() {
    super.initState();
    _loadBlurSettings();
    _setActionShortcut();
  }

  // 加载高斯模糊设置
  Future<void> _loadBlurSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isBlurEnabled = prefs.getBool('isBlurEnabled') ?? false;
    });
  }
  
  // action 快捷方式
  void _setActionShortcut() {
    const QuickActions quickActions = QuickActions();
    quickActions.initialize((String shortcutType) {
      setState(() {
        shortcut = shortcutType;
      });

      // 根据 shortcutType 跳转到对应页面
      if (shortcutType == 'action_one') {
        print('Action one triggered');
        // 打开网页
        launchUrl(Uri.parse('http://chuankuan.com.cn/weather'));
      } else if (shortcutType == 'action_two') {
        print('Action two triggered');
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => DailyNewsPage(),
          ),
        );
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_one',
        localizedTitle: '逸风天气',
        icon: "ic_launcher",
      ),
      const ShortcutItem(
        type: 'action_two',
        localizedTitle: '每日60分新闻',
        icon: 'ic_launcher',
      ),
    ]).then((void _) {
      setState(() {
        if (shortcut == 'no action set') {
          shortcut = 'actions ready';
        }
      });
    });
  }

  // 切换设备预览
  void _toggleDevicePreview() {
    setState(() {
      useDevicePreview = !useDevicePreview;
    });
  }
  
  // 切换夜间模式
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  // 切换高斯模糊
  void _toggleBlur() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isBlurEnabled = !isBlurEnabled;
    });
    await prefs.setBool('isBlurEnabled', isBlurEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: '遇见信息',
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: _isDarkMode
          ? ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF121212), // 深色背景
              primaryColor: const Color(0xFF1F1F1F), // 主色调
              cardColor: const Color(0xFF1E1E1E), // 卡片颜色
              appBarTheme: AppBarTheme(
                backgroundColor: const Color(0xFF1F1F1F),
                titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
                iconTheme: const IconThemeData(color: Colors.white), // AppBar 图标颜色
              ),
              iconTheme: const IconThemeData(color: Color(0xFFBB86FC)), // 全局图标着色（柔和紫色）
              textTheme: const TextTheme(
                titleLarge: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                labelLarge: TextStyle(
                  color: Color(0xFFBB86FC),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: const Color(0xFFBB86FC), // 浮动按钮颜色
              ),
            )
          : ThemeData(
              primarySwatch: Colors.deepPurple,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              textTheme: const TextTheme(
                titleLarge: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                labelLarge: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      home: MainPage(
        isDarkMode: _isDarkMode,
        useDevicePreview: useDevicePreview,
        toggleTheme: _toggleTheme,
        toggleDevicePreview: _toggleDevicePreview, // 传递切换方法
        isBlurEnabled: isBlurEnabled, // 传递高斯模糊状态
        toggleBlur: _toggleBlur, // 传递切换高斯模糊的方法
      ),
    );

    return useDevicePreview
        ? DevicePreview(
            enabled: true,
            builder: (context) => app,
            tools: [
              ...DevicePreview.defaultTools,
              DevicePreviewScreenshot(
                onScreenshot: (context, screenshot) async {
                  try {
                    // 使用 ImageGallerySaverPlus 保存截图
                    final result = await ImageGallerySaverPlus.saveImage(
                      screenshot.bytes,
                      name: 'screenshot_${DateTime.now().millisecondsSinceEpoch}',
                      quality: 100,
                    );

                    if (result != null && result['isSuccess']) {
                      Fluttertoast.showToast(msg: '截图已保存到相册');
                    } else {
                      throw Exception('保存截图失败');
                    }
                  } catch (e) {
                    Fluttertoast.showToast(msg: e.toString());
                  }
                },
              ),
            ],
          )
        : app;
  }
}
