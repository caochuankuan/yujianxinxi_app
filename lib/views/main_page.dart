import 'dart:convert';
import 'dart:io';
import 'package:clay_containers/constants.dart';
import 'package:clay_containers/widgets/clay_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lunar/calendar/Lunar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yifeng_site/views/bilibili/bilibili_page.dart';
import 'package:yifeng_site/views/bing_wallpaper/bing_wallpaper_page.dart';
import 'package:yifeng_site/views/browser/browser_page.dart';
import 'package:yifeng_site/views/news/daily_news_page.dart';
import 'package:yifeng_site/views/douyin/douyin_page.dart';
import 'package:yifeng_site/views/epic/epic_free_games_page.dart';
import 'package:yifeng_site/views/mingxing_bagua/mingxing_bagua.dart';
import 'package:yifeng_site/views/moyu_rili/moyu_rili.dart';
import 'package:yifeng_site/views/moyuribao_page/moyuribao_page.dart';
import 'package:yifeng_site/views/neihan_duanzi/neihan_duanzi.dart';
import 'package:yifeng_site/views/news/news_page.dart';
import 'package:yifeng_site/views/today_in_history/today_in_history_page.dart';
import 'package:yifeng_site/utils/update_checker.dart';
import 'package:yifeng_site/views/weibo/weibo_page.dart';
import 'package:yifeng_site/views/xingzuo_yunshi/xingzuo_yunshi.dart';
import 'package:yifeng_site/views/news/xinwen_jianbao.dart';
import 'package:yifeng_site/views/zhihu/zhihu_page.dart';
import 'package:yifeng_site/widgets/liquid_glass.dart';
import 'package:yifeng_site/widgets/liquid_glass_bottom_nav_bar.dart';
import 'package:yifeng_site/widgets/spotlight_search_dialog.dart';
import 'package:yifeng_site/widgets/web_viewer.dart';

class MainPage extends StatefulWidget {
  late final bool isDarkMode;
  final bool useDevicePreview;
  late final VoidCallback toggleTheme;
  late final VoidCallback toggleDevicePreview;
  final bool isBlurEnabled; // 高斯模糊状态
  final VoidCallback toggleBlur; // 切换高斯模糊的方法

  MainPage({super.key, 
    required this.isDarkMode,
    required this.toggleTheme,
    required this.useDevicePreview,
    required this.toggleDevicePreview,
    required this.isBlurEnabled,
    required this.toggleBlur,
  });

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Map<String, dynamic>? weatherData;
  bool isLoading = false;
  var location = '位置获取失败';

  // 背景设置相关
  String? _bgType; // 'asset' | 'network' | 'color' | 'gradient' | 'local_file'
  String? _bgValue; // 路径/URL/颜色值字符串

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    checkForUpdate(context, false);
    getLocationName(); // 获取位置名称
    _loadBgSetting();
  }

  Future<void> _loadBgSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bgType = prefs.getString('bgType') ?? 'asset';
      _bgValue = prefs.getString('bgValue') ?? 'assets/images/1.jpg';
    });
  }

  Future<void> _saveBgSetting(String type, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bgType', type);
    await prefs.setString('bgValue', value);
    setState(() {
      _bgType = type;
      _bgValue = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // final baseColor = isDark ? Color(0xFF2C2C2C) : Color(0xFFF0F0F3);

    // 动态背景渲染
    BoxDecoration bgDecoration;
    if (_bgType == 'asset') {
      bgDecoration = BoxDecoration(
        image: DecorationImage(
          image: AssetImage(_bgValue ?? 'assets/images/1.jpg'),
          fit: BoxFit.cover,
        ),
      );
    } else if (_bgType == 'network') {
      bgDecoration = BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(_bgValue ?? ''),
          fit: BoxFit.cover,
          onError: (e, s) {
            Fluttertoast.showToast(msg: '网络图片加载失败，已切换为默认背景');
            _saveBgSetting('asset', 'assets/images/1.jpg');
          },
        ),
      );
    } else if (_bgType == 'color') {
      bgDecoration = BoxDecoration(
        color: Color(int.tryParse(_bgValue ?? '') ?? 0xFFFFFFFF),
      );
    } else if (_bgType == 'gradient') {
      // value: 'color1,color2'
      final parts = (_bgValue ?? '').split(',');
      Color c1 = Colors.blue, c2 = Colors.purple;
      if (parts.length == 2) {
        c1 = Color(int.tryParse(parts[0]) ?? Colors.blue.value);
        c2 = Color(int.tryParse(parts[1]) ?? Colors.purple.value);
      }
      bgDecoration = BoxDecoration(
        gradient: LinearGradient(
          colors: [c1, c2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (_bgType == 'local_file') {
      bgDecoration = BoxDecoration(
        image: DecorationImage(
          image: FileImage(File(_bgValue ?? '')),
          fit: BoxFit.cover,
          onError: (e, s) {
            Fluttertoast.showToast(msg: '本地图片加载失败，已切换为默认背景');
            _saveBgSetting('asset', 'assets/images/1.jpg');
          },
        ),
      );
    } else {
      bgDecoration = BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/1.jpg'),
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      decoration: bgDecoration,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              title: const Text('遇见信息'),
              centerTitle: true,
              elevation: 0,
              leading: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () async {
                      final packageInfo = await PackageInfo.fromPlatform();
                      final currentVersion = packageInfo.version;
                      showAboutDialog(
                        context: context,
                        applicationName: '遇见信息',
                        applicationVersion: currentVersion,
                        applicationIcon: const Image(
                          image: AssetImage('assets/icon/app.png'),
                          width: 50,
                          height: 50,
                        ),
                        children: [
                          Text('作者：于逸风'),
                          Text('联系方式：2835082172@qq.com'),
                          Text('GitHub：https://github.com/caochuankuan/'),
                          ElevatedButton(
                            onPressed: () => checkForUpdate(context, true),
                            child: const Text('检查更新'),
                          ),
                        ],
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.web),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WebViewer(
                            isShowAppBar: true,
                            initialUrl: 'http://news.chuankuan.com.cn',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              leadingWidth: 96, // 调整leading宽度以适应两个按钮
              actions: [
                IconButton(
                  icon: Icon(widget.useDevicePreview
                      ? Icons.devices
                      : Icons.devices_outlined),
                  onPressed: widget.toggleDevicePreview, // 使用传入的方法
                ),
                IconButton(
                  icon: Icon(isDark
                      ? Icons.wb_sunny_outlined
                      : Icons.nightlight_round),
                  onPressed: widget.toggleTheme,
                ),
                IconButton(
                  icon: const Icon(Icons.image),
                  tooltip: '背景设置',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (context) {
                        String urlInput = '';
                        Color customColor = Colors.blue;
                        Color gradientStart = Colors.blue;
                        Color gradientEnd = Colors.purple;
                        // 使用 StateSetter 来更新 ModalBottomSheet 内部的状态
                        bool currentBlurEnabled = widget.isBlurEnabled;
                        return StatefulBuilder(
                          builder: (context, setModalState) {
                            return Padding(
                              padding: MediaQuery.of(context).viewInsets,
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 12),
                                    const Text('选择背景', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 12),
                                    // 预设图片
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: List.generate(5, (i) {
                                          final imgPath = 'assets/images/${i+1}.jpg';
                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.pop(context, {'type': 'asset', 'value': imgPath});
                                            },
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.asset(
                                                imgPath,
                                                width: 56,
                                                height: 56,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // 网络图片
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              decoration: const InputDecoration(
                                                labelText: '输入图片URL',
                                                border: OutlineInputBorder(),
                                              ),
                                              onChanged: (v) {
                                                setModalState(() { urlInput = v; });
                                              },
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.check),
                                            onPressed: urlInput.trim().isNotEmpty
                                                ? () {
                                                    Navigator.pop(context, {'type': 'network', 'value': urlInput.trim()});
                                                  }
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (urlInput.trim().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Image.network(
                                          urlInput,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) {
                                            Fluttertoast.showToast(msg: '图片加载失败');
                                            return const Icon(Icons.broken_image);
                                          },
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                    // 本地选择图片按钮
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(Icons.photo_library),
                                              label: const Text('本地选择图片'),
                                              onPressed: () async {
                                                final ImagePicker picker = ImagePicker();
                                                final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                                                if (image != null) {
                                                  Navigator.pop(context, {'type': 'local_file', 'value': image.path});
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // 纯色选择
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          Colors.white, Colors.black, Colors.blue, Colors.green, Colors.pink, Colors.orange
                                        ].map((color) => GestureDetector(
                                          onTap: () {
                                            Navigator.pop(context, {'type': 'color', 'value': color.value.toString()});
                                          },
                                          child: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: color,
                                              border: Border.all(width: 2, color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(18),
                                            ),
                                          ),
                                        )).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // 自定义纯色按钮
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(Icons.palette),
                                              label: const Text('自定义纯色'),
                                              onPressed: () async {
                                                await showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      title: const Text('选择颜色'),
                                                      content: SingleChildScrollView(
                                                        child: ColorPicker(
                                                          pickerColor: customColor,
                                                          onColorChanged: (color) {
                                                            setModalState(() { customColor = color; });
                                                          },
                                                          enableAlpha: false,
                                                          showLabel: true,
                                                          pickerAreaHeightPercent: 0.7,
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          child: const Text('取消'),
                                                          onPressed: () => Navigator.of(context).pop(),
                                                        ),
                                                        TextButton(
                                                          child: const Text('确定'),
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                            Navigator.pop(context, {'type': 'color', 'value': customColor.value.toString()});
                                                          },
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // 自定义渐变按钮
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(Icons.gradient),
                                              label: const Text('自定义渐变'),
                                              onPressed: () async {
                                                await showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      title: const Text('选择渐变色'),
                                                      content: SingleChildScrollView(
                                                        child: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const Text('起始色'),
                                                            ColorPicker(
                                                              pickerColor: gradientStart,
                                                              onColorChanged: (color) {
                                                                setModalState(() { gradientStart = color; });
                                                              },
                                                              enableAlpha: false,
                                                              showLabel: true,
                                                              pickerAreaHeightPercent: 0.5,
                                                            ),
                                                            const SizedBox(height: 8),
                                                            const Text('结束色'),
                                                            ColorPicker(
                                                              pickerColor: gradientEnd,
                                                              onColorChanged: (color) {
                                                                setModalState(() { gradientEnd = color; });
                                                              },
                                                              enableAlpha: false,
                                                              showLabel: true,
                                                              pickerAreaHeightPercent: 0.5,
                                                            ),
                                                            const SizedBox(height: 8),
                                                            Container(
                                                              width: 120,
                                                              height: 32,
                                                              decoration: BoxDecoration(
                                                                gradient: LinearGradient(
                                                                  colors: [gradientStart, gradientEnd],
                                                                ),
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          child: const Text('取消'),
                                                          onPressed: () => Navigator.of(context).pop(),
                                                        ),
                                                        TextButton(
                                                          child: const Text('确定'),
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                            Navigator.pop(context, {
                                                              'type': 'gradient',
                                                              'value': '${gradientStart.value},${gradientEnd.value}'
                                                            });
                                                          },
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // 高斯模糊开关
                                    SwitchListTile(
                                      title: const Text('高斯模糊背景'),
                                      value: currentBlurEnabled, // 使用局部状态
                                      onChanged: (newValue) {
                                        setModalState(() {
                                          currentBlurEnabled = newValue;
                                        });
                                        widget.toggleBlur(); // 调用传入的切换方法
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ).then((result) {
                      if (result != null && result is Map) {
                        _saveBgSetting(result['type'] as String, result['value'].toString());
                      }
                    });
                  },
                ),
              ],
            ),
            body: _buildBodyByIndex(_selectedIndex, isDark),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: LiquidGlassBottomNavBar(
              selectedIndex: _selectedIndex,
              isBlurEnabled: widget.isBlurEnabled,
              onItemTapped: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: buildDefaultNavBarItems(),
              onSearchTap: () {
                showSpotlightSearchDialog(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyByIndex(int index, bool isDark) {
    // 你可以根据 index 返回不同的内容
    // 这里只是简单示例，实际可自定义
    if (index == 0) {
      // 原有 CustomScrollView
      return BackdropGroup(
        child: CustomScrollView(
          slivers: <Widget>[
            // 天气组件
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8.0),
                child: LiquidGlass(
                  tint: isDark ? Colors.black : Colors.white,
                  isBlurEnabled: widget.isBlurEnabled, // 传递高斯模糊状态
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        isLoading
                            ? Container(
                                decoration: BoxDecoration(),
                                height: 180,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : weatherData == null
                                ? Container(
                                    decoration: BoxDecoration(),
                                      height: 180, // 设置与有数据时相近的高度
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                : Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                  maxLines: 2, // 限制最多显示两行
                                                  overflow: TextOverflow
                                                      .ellipsis, // 超出部分显示省略号
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
                                                        width: 24,
                                                        height: 24,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                  Color>(widget
                                                                      .isDarkMode
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black87),
                                                        ),
                                                      )
                                                    : const Icon(Icons.refresh),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.7,
                                            child: Text(
                                              weatherData!['hourly']
                                                  ['description'],
                                            ),
                                          ),
                                          Text(
                                            '降水概率: ${weatherData!['hourly']['precipitation'][0]['probability']}%',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Theme.of(context).brightness ==
                                                          Brightness.dark
                                                      ? Colors.grey[300]
                                                      : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            '体感温度: ${weatherData!['hourly']['apparent_temperature'][0]['value']}°C',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Theme.of(context).brightness ==
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
                                              color:
                                                  Theme.of(context).brightness ==
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
                                              color:
                                                  Theme.of(context).brightness ==
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
                                              color:
                                                  Theme.of(context).brightness ==
                                                          Brightness.dark
                                                      ? Colors.grey[300]
                                                      : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Spacer(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            children: [
                                              SizedBox(
                                                height: 30,
                                              ),
                                              getWeatherIcon(
                                                  weatherData!['hourly']
                                                      ['cloudrate'][0]['value']),
                                              Text(
                                                '${getWeatherDescription(weatherData!['hourly']['cloudrate'][0]['value'])}\n${weatherData!['hourly']['temperature'][0]['value']}°C', // 具体天气情况
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Theme.of(context)
                                                              .brightness ==
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
            // 主功能组件
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final item = _listItems[index];
                  // final baseColor =
                  //     isDark ? Color(0xFF2C2C2C) : Color(0xFFF0F0F3);

                  return Padding(
                    padding: EdgeInsets.all(4.0),
                    child: GestureDetector(
                      onTap: () {
                        if (item['page'] is Text) {
                          Fluttertoast.showToast(msg: '该功能正在开发中，敬请期待');
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => item['page']),
                        );
                      },
                      child: LiquidGlass(
                        tint: isDark ? Colors.black : Colors.white,
                        isBlurEnabled: widget.isBlurEnabled, // 传递高斯模糊状态
                        child: Container(
                          padding: EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ClayContainer(
                                height: 50,
                                width: 50,
                                depth: 80,
                                spread: 0,
                                borderRadius: 35,
                                curveType: CurveType.convex,
                                color: _bgType ==  "color" ? Color(int.tryParse(_bgValue ?? '') ?? 0xFFFFFFFF) : isDark ? const Color.fromARGB(255, 51, 44, 22) : Color.fromARGB(11, 204, 253, 204),
                                child: Icon(
                                  item['icon'],
                                  size: 32,
                                  // color: isDark
                                  //     ? Color.fromARGB(255, 230, 225, 236)
                                  //     : const Color.fromARGB(255, 99, 98, 102),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                item['text'],
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: _listItems.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            // 次功能组件
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
                    isDark ? Colors.grey[700]! : Colors.orangeAccent,
                    isDark ? Colors.white : Colors.black87,
                    isImageSection: true,
                    isDark: isDark,
                  );
                },
                childCount: _imageItems.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        )
      );
    } else if (index == 1) {
      // 展示主功能区
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.2,
        ),
        itemCount: _listItems.length,
        itemBuilder: (context, idx) {
          final item = _listItems[idx];
          return Padding(
            padding: EdgeInsets.all(4.0),
            child: GestureDetector(
              onTap: () {
                if (item['page'] is Text) {
                  Fluttertoast.showToast(msg: '该功能正在开发中，敬请期待');
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => item['page']),
                );
              },
              child: LiquidGlass(
                tint: isDark ? Colors.black : Colors.white,
                isBlurEnabled: widget.isBlurEnabled, // 传递高斯模糊状态
                child: Container(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ClayContainer(
                        height: 50,
                        width: 50,
                        depth: 80,
                        spread: 0,
                        borderRadius: 35,
                        curveType: CurveType.convex,
                        color: _bgType ==  "color" ? Color(int.tryParse(_bgValue ?? '') ?? 0xFFFFFFFF) : isDark ? const Color.fromARGB(255, 51, 44, 22)  : Color.fromARGB(11, 204, 253, 204),
                        child: Icon(
                          item['icon'],
                          size: 32,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        item['text'],
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else if (index == 2) {
      // 展示次功能区
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 1,
        ),
        itemCount: _imageItems.length,
        itemBuilder: (context, idx) {
          final item = _imageItems[idx];
          return _buildCard(
            context,
            item['text']!,
            item['icon']!,
            item['page']!,
            isDark ? Colors.grey[700]! : Colors.orangeAccent,
            isDark ? Colors.white : Colors.black87,
            isImageSection: true,
            isDark: isDark,
          );
        },
      );
    } else if (index == 3) {
      // 展示webview新闻
      return const WebViewer(
        isShowAppBar: false,
        initialUrl: 'http://news.chuankuan.com.cn',
      );
    } else {
      // 搜索按钮或其他
      return Center(child: Text('搜索功能开发中', style: TextStyle(fontSize: 20)));
    }
  }

  Widget _buildCard(
    BuildContext context,
    String text,
    IconData icon,
    Widget page,
    Color backgroundColor,
    Color textColor, {
    bool isImageSection = false,
    bool isDark = false,
  }) {
    // final baseColor = isDark
    //     ? Color(0xFF2C2C2C)
    //     : Color.fromARGB(255, 252, 244, 244);

    return Padding(
      padding: EdgeInsets.all(6.0),
      child: GestureDetector(
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
        child: LiquidGlass(
          tint: isDark ? Colors.black : Colors.white,
          isBlurEnabled: widget.isBlurEnabled, // 使用 widget.isBlurEnabled
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ClayContainer(
                height: isImageSection ? 45 : 60,
                width: isImageSection ? 45 : 60,
                depth: 80,
                spread: 0,
                borderRadius: isImageSection ? 23 : 30,
                curveType: CurveType.convex,
                color: _bgType ==  "color" ? Color(int.tryParse(_bgValue ?? '') ?? 0xFFFFFFFF) : isDark ? Colors.blue.shade100 : Color.fromARGB(10, 175, 255, 255),
                child: Icon(
                  icon,
                  size: isImageSection ? 24 : 30,
                  // color: isDark
                  //     ? Color(0xFFBB86FC)
                  //     : Colors.deepPurpleAccent,
                ),
              ),
              SizedBox(height: 8),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: isImageSection ? 13 : 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
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
      Position position = Position(
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
          
          fetchWeatherData();

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
        location = "佛山南海"; // 可以根据需求设置一个合适的默认值
      });
      
      fetchWeatherData();
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
      setState(() {
        isLoading = true; // 开始加载时设置状态
        weatherData = null; // 清空现有数据，触发加载状态
      });
      isAllowFresh = false;

      try {
        await getLocationName(); // 获取位置名称
      } catch (e) {
        print('Error refreshing weather: $e');
      } finally {
        setState(() {
          isLoading = false; // 无论成功失败都结束加载状态
        });

        await Future.delayed(Duration(seconds: 60)); // 等待1分钟
        isAllowFresh = true;
      }
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
      'page': DailyNewsPage(),
    },
    {
      'text': '逸风浏览器',
      'icon': Icons.public,
      'page': const BrowserPage(),
    },
    {
      'text': '抖音热搜',
      'icon': Icons.trending_up,
      'page': DouyinPage(),
    },
    {
      'text': 'Bilibili热搜',
      'icon': Icons.video_library,
      'page': BilibiliPage(),
    },
  ];

  final List<Map<String, dynamic>> _imageItems = [
    {
      'text': '头条热搜',
      'icon': Icons.dashboard,
      'page': NewsPage(),
    },
    {
      'text': '知乎热搜',
      'icon': Icons.question_answer,
      'page': ZhihuPage(),
    },
    {
      'text': '微博热搜',
      'icon': Icons.public,
      'page': WeiboPage(),
    },
    {
      'text': '摸鱼日报',
      'icon': Icons.today,
      'page': MoyuRibaoPage(),
    },
    {
      'text': '新闻简报',
      'icon': Icons.newspaper,
      'page': XinwenJianbaoPage(),
    },
    {
      'text': '历史上的今天',
      'icon': Icons.history,
      'page': TodayInHistoryPage(),
    },
    {
      'text': '全球票房榜',
      'icon': Icons.movie,
      // 'page': GlobalBoxOfficePage(),
      'page': BrowserPage(
        url: 'https://piaofang.maoyan.com/i/globalBox/historyRank',
      ),
    },
    {
      'text': 'Bing 每日壁纸',
      'icon': Icons.image,
      'page': BingWallpaperPage(),
    },
    {
      'text': 'Epic 免费游戏',
      'icon': Icons.games,
      'page': EpicFreeGamesPage(),
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
      'text': '明星八卦',
      'icon': Icons.star,
      'page': MingxingBaguaPage(),
    },
    {
      'text': '待开发',
      'icon': Icons.hourglass_empty,
      'page': Text('待开发'),
    },
  ];
}