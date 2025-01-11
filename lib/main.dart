import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart'; // 导入 geolocator
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lunar/lunar.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yifeng_site/bilibili_page.dart';
import 'package:yifeng_site/bing_wallpaper_page.dart';
import 'package:yifeng_site/daily_news_page.dart';
import 'package:yifeng_site/epic_free_games_page.dart';
import 'package:yifeng_site/mingxing_bagua.dart';
import 'package:yifeng_site/moyu_rili.dart';
import 'package:yifeng_site/moyuribao_page.dart';
import 'package:yifeng_site/neihan_duanzi.dart';
import 'package:yifeng_site/today_in_history_page.dart';
import 'package:yifeng_site/weibo_page.dart';
import 'package:yifeng_site/xingzuo_yunshi.dart';
import 'package:yifeng_site/xinwen_jianbao.dart';
import 'package:yifeng_site/zhihu_page.dart';
import 'douyin_page.dart';
import 'news_page.dart';
import 'package:quick_actions/quick_actions.dart';

// 主程序入口
void main() {
  runApp(const MyApp());
}

// 主应用程序的根部件
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // 定义一个布尔变量来控制是否为夜间模式
  bool _isDarkMode = false;
  String shortcut = 'no action set';
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

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
          MaterialPageRoute(builder: (context) => DailyNewsPage(futureData: fetchDailyNewsData(),)),
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: '遇见信息',
      theme: _isDarkMode
          ? ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF121212), // 深色背景
              primaryColor: const Color(0xFF1F1F1F), // 主色调
              cardColor: const Color(0xFF1E1E1E), // 卡片颜色
              appBarTheme: AppBarTheme(
                backgroundColor: const Color(0xFF1F1F1F),
                titleTextStyle:
                    const TextStyle(color: Colors.white, fontSize: 20),
                iconTheme:
                    const IconThemeData(color: Colors.white), // AppBar 图标颜色
              ),
              iconTheme:
                  const IconThemeData(color: Color(0xFFBB86FC)), // 全局图标着色（柔和紫色）
              textTheme: const TextTheme(
                titleLarge: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
                labelLarge: TextStyle(
                    color: Color(0xFFBB86FC),
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: const Color(0xFFBB86FC), // 浮动按钮颜色
              ),
            )
          : ThemeData(
              primarySwatch: Colors.deepPurple,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              textTheme: const TextTheme(
                titleLarge:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                labelLarge:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
      home: Yifeng(
        isDarkMode: _isDarkMode,
        toggleTheme: _toggleTheme,
      ),
    );
  }

  // 切换夜间模式的方法
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }
}

class Yifeng extends StatefulWidget {
  late final bool isDarkMode;
  late final VoidCallback toggleTheme;
  Yifeng({required this.isDarkMode, required this.toggleTheme});

  @override
  _YifengState createState() => _YifengState();
}

// 主页面部件
class _YifengState extends State<Yifeng> {
  Map<String, dynamic>? weatherData;
  bool isLoading = false;
  var location = '位置获取失败';

  @override
  void initState() {
    super.initState();
    getLocationName(); // 获取位置名称
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('遇见信息'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            showAboutDialog(
              context: context,
              applicationName: '遇见信息',
              applicationVersion: '1.0.1',
              applicationIcon: const Image(
                image: AssetImage('assets/icon/app.png'),
                width: 50,
                height: 50,
              ),
              children: [
                Text('作者：于逸风'),
                Text('联系方式：2835082172@qq.com'),
                Text('GitHub：https://github.com/caochuankuan/'),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode
                ? Icons.wb_sunny_outlined
                : Icons.nightlight_round),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          // 添加天气组件
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 0.0, vertical: 8.0), // 外部边距
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0), // 圆角卡片
                ),
                elevation: 4.0, // 卡片阴影
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0), // 圆角
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[900]
                        : Colors.amberAccent, // 背景颜色
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      weatherData == null
                          ? const Center(
                              child: CircularProgressIndicator(), // 显示加载状态
                            )
                          : Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.62,
                                          child: Text(
                                            location, // 显示城市名称
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: refreshWeatherData,
                                          icon: isLoading
                                              ? SizedBox(
                                                  width: 12,
                                                  height: 12,
                                                  child:
                                                      const CircularProgressIndicator(
                                                    strokeWidth: 1,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors.white),
                                                  ),
                                                )
                                              : const Icon(Icons.refresh),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.7,
                                      child: Text(
                                        weatherData!['hourly']['description'],
                                      ),
                                    ),
                                    Text(
                                      '降水概率: ${weatherData!['hourly']['precipitation'][0]['probability']}%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[300]
                                            : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      '体感温度: ${weatherData!['hourly']['apparent_temperature'][0]['value']}°C',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[300]
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '风速: ${weatherData!['hourly']['wind'][0]['speed']} m/s',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[300]
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '农历: ${Lunar.fromDate(DateTime.now()).toString()}', // 农历日期
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[300]
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '星期: ${DateFormat.EEEE().format(DateTime.now())}', // 显示星期几
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[300]
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                Spacer(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      children: [
                                        SizedBox(
                                          height: 30,
                                        ),
                                        getWeatherIcon(weatherData!['hourly']
                                            ['cloudrate'][0]['value']),
                                        Text(
                                          '${getWeatherDescription(weatherData!['hourly']['cloudrate'][0]['value'])}\n${weatherData!['hourly']['temperature'][0]['value']}°C', // 具体天气情况
                                          style: TextStyle(
                                            fontSize: 16,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey[300]
                                                    : Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            )
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 1.2,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final item = _listItems[index];
                return _buildCard(
                  context,
                  item['text']!,
                  item['icon']!,
                  item['page']!,
                  widget.isDarkMode
                      ? Colors.grey[800]!
                      : Colors.deepPurpleAccent,
                  widget.isDarkMode ? Colors.white : Colors.white,
                );
              },
              childCount: _listItems.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final item = _imageItems[index];
                return _buildCard(
                  context,
                  item['text']!,
                  item['icon']!,
                  item['page']!,
                  widget.isDarkMode ? Colors.grey[700]! : Colors.orangeAccent,
                  widget.isDarkMode ? Colors.white : Colors.black87,
                  isImageSection: true,
                );
              },
              childCount: _imageItems.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String text,
    IconData icon,
    Widget page,
    Color backgroundColor,
    Color textColor, {
    bool isImageSection = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (page is Text) {
          Fluttertoast.showToast(msg: '该功能正在开发中，敬请期待');
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(0.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                height: isImageSection ? 80 : 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: isImageSection ? 45 : 50,
                  color: widget.isDarkMode
                      ? isImageSection
                          ? Color.fromARGB(255, 175, 208, 219)
                          : Color.fromARGB(255, 180, 158, 208)
                      : textColor, // 根据模式设置图标颜色
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: isImageSection ? 15 : 20,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 获取天气数据并缓存
  Future<void> fetchWeatherData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 获取设备当前位置
      Position position = await _determinePosition();

      // 使用当前经纬度构建 API 请求
      final response = await http.get(Uri.parse(
        'https://api.caiyunapp.com/v2.6/h8T0Rl89rMPeV37x/${position.longitude},${position.latitude}/hourly?hourlysteps=10',
      ));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'ok') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'weatherData', jsonEncode(jsonResponse['result']));
          await prefs.setString(
              'lastFetchTime', DateTime.now().toIso8601String());

          setState(() {
            weatherData = jsonResponse['result'];
            print(weatherData);
          });
        } else {
          throw Exception('Failed to load weather data');
        }
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      print('Error: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  Position createDefaultPosition() {
    // 返回一个默认的 Position 对象
    return Position(
      latitude: 23.050556, // 示例纬度（北京）
      longitude: 113.138611, // 示例经度（北京）
      timestamp: DateTime.now(), // 当前时间
      accuracy: 10.0, // 假设的精确度，单位：米
      altitude: 0.0, // 假设的海拔高度，单位：米
      altitudeAccuracy: 5.0, // 假设的海拔精确度，单位：米
      heading: 0.0, // 假设的方向，单位：度
      headingAccuracy: 0.0, // 假设的方向精度，单位：度
      speed: 0.0, // 假设的速度，单位：米/秒
      speedAccuracy: 0.0, // 假设的速度精确度，单位：米/秒
    );
  }

  // 获取地点名称
  Future<void> getLocationName() async {
    try {
      // 设置 10 秒超时，获取设备当前位置
      Position position = await _determinePosition().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          // 超时处理，显示默认地址并弹出提示
          Fluttertoast.showToast(
            msg: "获取位置失败，使用默认地点",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );

          // 设置默认地点，例如 "北京市"
          setState(() {
            location = "佛山南海";
          });

          // 继续执行：如果你希望在超时后继续执行剩余的逻辑，返回一个假定的位置
          return createDefaultPosition();
        },
      );

      // 构建 API 请求 URL
      final myLocation = await http.get(Uri.parse(
          'https://restapi.amap.com/v3/geocode/regeo?output=JSON&location=${position.longitude},${position.latitude}&key=35971d64d5b9f2b3d7086c3fc3457825'));

      print("myLocation: $myLocation");

      // 检查请求是否成功
      if (myLocation.statusCode == 200) {
        // 解析 JSON 响应
        final jsonResponse = jsonDecode(myLocation.body);
        print("jsonResponse: $jsonResponse");

        // 检查是否存在 regeocode 并提取 formatted_address
        if (jsonResponse['regeocode'] != null) {
          final formattedAddress =
              jsonResponse['regeocode']['formatted_address'];
          print('Address: $formattedAddress');
          setState(() {
            location = formattedAddress;
          });
        } else {
          // 如果未找到地址，则使用经纬度
          print('No address found');
          setState(() {
            location = '${position.latitude},${position.longitude}';
          });
        }

        // 获取天气数据
        fetchWeatherData();
        return;
      } else {
        // 如果请求失败，显示经纬度并抛出异常
        setState(() {
          location = '${position.latitude},${position.longitude}';
        });
        throw Exception('Failed to load address');
      }
    } catch (e) {
      // 捕获其他异常并提示错误
      Fluttertoast.showToast(
        msg: "获取位置失败，请稍后再试",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      setState(() {
        location = "获取位置失败"; // 可以根据需求设置一个合适的默认值
      });
    }
  }

  // 获取当前位置的函数
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 检查位置服务是否启用
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 位置服务不可用，提示用户开启
      return Future.error('Location services are disabled.');
    }

    // 检查是否具有位置权限
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // 权限被拒绝，无法继续
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // 权限被永久拒绝
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // 获取当前位置
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      forceAndroidLocationManager: true,
      timeLimit: Duration(seconds: 10),  
    );
  }

  bool isAllowFresh = true;

  // 手动刷新天气数据
  Future<void> refreshWeatherData() async {
    if (isAllowFresh) {
      isAllowFresh = false;
      Fluttertoast.showToast(msg: '正在刷新天气数据，请稍候');
      await getLocationName(); // 获取位置名称
      await Future.delayed(Duration(seconds: 60)); // 等待1分钟
      isAllowFresh = true;
    } else {
      Fluttertoast.showToast(msg: '请不要频繁刷新，请等待1分钟后再刷新');
    }
  }

  Widget getWeatherIcon(double cloudRate) {
    if (cloudRate < 0.2) {
      return Icon(
        Icons.wb_sunny,
        size: 39,
      );
    } else if (cloudRate < 0.5) {
      return Icon(
        Icons.wb_cloudy,
        size: 39,
      );
    } else if (cloudRate < 0.8) {
      return Icon(
        Icons.cloud,
        size: 39,
      );
    } else {
      return Icon(
        Icons.cloud,
        size: 39,
      );
    }
  }

  // 天气状况判定
  String getWeatherDescription(double cloudRate) {
    String weatherCondition;
    if (cloudRate < 0.2) {
      weatherCondition = '晴朗';
    } else if (cloudRate < 0.5) {
      weatherCondition = '少云';
    } else if (cloudRate < 0.8) {
      weatherCondition = '多云';
    } else {
      weatherCondition = '阴天';
    }
    return weatherCondition;
  }

  Future<String> getLunarDate() async {
    DateTime now = DateTime.now();
    Lunar lunar = Lunar.fromDate(now);

    return "${lunar.getYearInChinese()}年${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}";
  }

  final List<Map<String, dynamic>> _listItems = [
    {
      'text': '每日60秒',
      'icon': Icons.access_time,
      'page': DailyNewsPage(futureData: fetchDailyNewsData()),
    },
    {
      'text': '摸鱼日报',
      'icon': Icons.today,
      'page': MoyuRibaoPage(),
    },
    {
      'text': '历史上的今天',
      'icon': Icons.history,
      'page': TodayInHistoryPage(),
    },
    {
      'text': '抖音热搜',
      'icon': Icons.trending_up,
      'page': DouyinPage(),
    }
  ];

  final List<Map<String, dynamic>> _imageItems = [
    {
      'text': 'Bilibili热搜',
      'icon': Icons.video_library,
      'page': BilibiliPage(),
    },
    {
      'text': 'Bing 每日壁纸',
      'icon': Icons.image,
      'page': BingWallpaperPage(futureData: fetchBingWallpaperData()),
    },
    {
      'text': 'Epic 免费游戏',
      'icon': Icons.games,
      'page': EpicFreeGamesPage(futureGames: fetchEpicFreeGames()),
    },
    {
      'text': '摸鱼日历',
      'icon': Icons.calendar_today,
      'page': MoyuRiliPage(),
    },
    {
      'text': '内涵段子',
      'icon': Icons.sentiment_satisfied,
      'page': NeihanDuanziPage(),
    },
    {
      'text': '星座运势',
      'icon': Icons.star_border,
      'page': XingzuoYunshiPage(),
    },
    {
      'text': '头条热搜',
      'icon': Icons.dashboard,
      'page': NewsPage(),
    },
    {
      'text': '知乎热搜',
      'icon': Icons.question_answer,
      'page': ZhihuPage(futureData: fetchZhihuData()),
    },
    {
      'text': '微博热搜',
      'icon': Icons.public,
      'page': WeiboPage(futureData: fetchWeiboData()),
    },
    {
      'text': '明星八卦',
      'icon': Icons.star,
      'page': MingxingBaguaPage(),
    },
    {
      'text': '新闻简报',
      'icon': Icons.newspaper,
      'page': XinwenJianbaoPage(),
    },
    {
      'text': '待开发',
      'icon': Icons.hourglass_empty,
      'page': Text('待开发'),
    },
  ];
}
