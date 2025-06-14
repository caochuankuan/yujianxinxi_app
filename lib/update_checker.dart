import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> checkForUpdate(BuildContext context, bool showToast) async {
  const versionUrl = 'http://chuankuan.com.cn/appupdate/version.json';

  try {
    final response = await http.get(Uri.parse(versionUrl));
    if (response.statusCode != 200) {
      throw Exception('网络请求失败：${response.statusCode}');
    }

    final data = json.decode(response.body);
    final remoteVersion = (data['version'] ?? '').replaceAll('v', '');
    final apkUrl = data['apk_url'] ?? '';
    final changelog = data['changelog'] ?? '';

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    if (_isNewerVersion(remoteVersion, currentVersion)) {
      _showUpdateDialog(context, remoteVersion, apkUrl, changelog);
    } else {
      debugPrint('已是最新版本');
      if (showToast) {
        Fluttertoast.showToast(msg: "已是最新版本");
      }
    }
  } catch (e) {
    debugPrint('检查更新失败：$e');
  }
}

bool _isNewerVersion(String remote, String local) {
  List<int> r = remote.split('.').map(int.parse).toList();
  List<int> l = local.split('.').map(int.parse).toList();

  for (int i = 0; i < r.length; i++) {
    if (i >= l.length || r[i] > l[i]) return true;
    if (r[i] < l[i]) return false;
  }
  return false;
}

void _showUpdateDialog(BuildContext context, String version, String apkUrl, String changelog) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('发现新版本 v$version'),
      content: Text(changelog.isEmpty ? '有新版本可用，是否立即更新？' : changelog),
      actions: [
        TextButton(
          child: const Text('取消'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('下载更新'),
          onPressed: () async {
            Navigator.of(context).pop();
            if (await canLaunchUrl(Uri.parse(apkUrl))) {
              await launchUrl(Uri.parse(apkUrl), mode: LaunchMode.externalApplication);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('无法打开下载链接')),
              );
            }
          },
        ),
      ],
    ),
  );
}