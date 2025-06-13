import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/logger.dart';

class BingImageService {
  static const String _bingApiUrl = 'https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=zh-CN';
  static const String _backgroundDir = 'background_image';
  static const int _maxImages = 5;
  
  final _logger = AppLogger.forClass(BingImageService);
  final Dio _dio = Dio();
  
  BingImageService() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }
  
  /// 获取背景图片目录
  Future<Directory> _getBackgroundDirectory() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final backgroundDir = Directory(path.join(appSupportDir.path, _backgroundDir));
    
    if (!await backgroundDir.exists()) {
      await backgroundDir.create(recursive: true);
    }
    
    return backgroundDir;
  }
  
  /// 获取最新的背景图片文件
  Future<File?> getLatestBackgroundImage() async {
    try {
      final backgroundDir = await _getBackgroundDirectory();
      final files = backgroundDir.listSync()
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.jpg'))
          .toList();
      
      if (files.isEmpty) {
        return null;
      }
      
      // 按修改时间排序，获取最新的文件
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return files.first;
    } catch (e) {
      _logger.e('获取最新背景图片失败: $e');
      return null;
    }
  }
  
  /// 清理旧的图片文件，保持最多5张
  Future<void> _cleanupOldImages() async {
    try {
      final backgroundDir = await _getBackgroundDirectory();
      final files = backgroundDir.listSync()
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.jpg'))
          .toList();
      
      if (files.length <= _maxImages) {
        return;
      }
      
      // 按修改时间排序，删除最旧的文件
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      
      for (int i = _maxImages; i < files.length; i++) {
        try {
          await files[i].delete();
          _logger.i('删除旧背景图片: ${files[i].path}');
        } catch (e) {
          _logger.w('删除旧背景图片失败: ${files[i].path}, 错误: $e');
        }
      }
    } catch (e) {
      _logger.e('清理旧图片失败: $e');
    }
  }
  
  /// 下载Bing每日壁纸
  Future<void> downloadDailyWallpaper() async {
    try {
      _logger.i('开始下载Bing每日壁纸');
      
      // 获取Bing图片信息
      final response = await _dio.get(_bingApiUrl);
      final data = response.data;
      
      if (data['images'] == null || data['images'].isEmpty) {
        _logger.w('Bing API返回的图片信息为空');
        return;
      }
      
      final imageInfo = data['images'][0];
      final imageUrl = 'https://www.bing.com${imageInfo['url']}';
      final imageTitle = imageInfo['title'] ?? 'bing_wallpaper';
      
      // 生成文件名（使用日期和标题）
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final fileName = '${dateStr}_${_sanitizeFileName(imageTitle)}.jpg';
      
      final backgroundDir = await _getBackgroundDirectory();
      final filePath = path.join(backgroundDir.path, fileName);
      
      // 检查文件是否已存在
      final file = File(filePath);
      if (await file.exists()) {
        _logger.i('今日壁纸已存在: $fileName');
        return;
      }
      
      // 下载图片
      _logger.i('下载图片: $imageUrl');
      await _dio.download(imageUrl, filePath);
      
      _logger.i('壁纸下载成功: $fileName');
      
      // 清理旧图片
      await _cleanupOldImages();
      
    } catch (e) {
      _logger.e('下载Bing每日壁纸失败: $e');
    }
  }
  
  /// 清理文件名中的非法字符
  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .substring(0, fileName.length > 50 ? 50 : fileName.length);
  }
  
  /// 初始化服务（在应用启动时调用）
  static Future<void> initialize() async {
    final service = BingImageService();
    // 异步下载，不阻塞应用启动
    service.downloadDailyWallpaper().catchError((e) {
      AppLogger.logger.e('BingImageService初始化失败: $e');
    });
  }
}