import 'dart:io';
import 'package:dio/dio.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

import '../utils/logger.dart';

enum SyncOperation {
  fetch,
  pull,
  noop,
}

class WebdavService {
  late webdav.Client _client;
  late String _path;

  final _logger = AppLogger.forClass(WebdavService);

  WebdavService(String host, String user, String password, String path) {
    _createWebDavClient(host, user, password, path);
  }

  WebdavService.fromMap(Map<String, dynamic> configMap) {
    var host = configMap['host'];
    var user = configMap['user'];
    var password = configMap['passwd'];
    var path = configMap['path'];

    _createWebDavClient(host, user, password, path);
  }

  void _createWebDavClient(String host, String user, String password, String path) {
    _logger.i('Creating WebDAV client for $host \n user: $user \n password: $password \n path $path');
    _client = webdav.newClient(host, user: user, password: password);

    _client.setHeaders({'accept-charset': 'utf-8'});
    _client.setConnectTimeout(8000);
    _client.setSendTimeout(8000);
    _client.setReceiveTimeout(8000);

    _path = path;
  }

  Future<void> fetchFile(String remoteFilePath, String localFilePath) async {
    try {
      // Download from WebDAV to local file.
      remoteFilePath = '$_path/$remoteFilePath';
      await _client.read2File(remoteFilePath, localFilePath);
    } catch (e) {
      _logger.e('Error fetching file from WebDAV: $e');
    }
  }

  Future<void> pullFile(String localFilePath, String remoteFilePath) async {
    try {
      // Upload local temp file to WebDAV
      remoteFilePath = '$_path/$remoteFilePath';
      await _client.writeFromFile(localFilePath, remoteFilePath);
    } catch (e, s) {
      _logger.e('Error updating file on WebDAV: $e \n $s');
    }
  }

  Future<SyncOperation> checkFile(String localFilePath, String remoteFilePath) async {
    remoteFilePath = '$_path/$remoteFilePath';
    webdav.File remoteFile;
    try {
       remoteFile = await _client.readProps(remoteFilePath);
    }
    catch (e, s) {
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          return SyncOperation.pull;
        }
      }
      _logger.e('Error checking file on WebDAV: $e \n $s');
      return SyncOperation.noop;
    }
   
    var localFile = File(localFilePath);

    if (!localFile.existsSync()) {
      return SyncOperation.fetch;
    }
    
    var localFileMoidfyTime = await localFile.lastModified();
    var remoteFileMoidfyTime = remoteFile.mTime;

    if (remoteFileMoidfyTime == null) {
      _logger.e('Error getting remote file modify time');
      return SyncOperation.noop;
    }

    if (localFileMoidfyTime.isAfter(remoteFileMoidfyTime)) {
      return SyncOperation.pull;
    } else if (localFileMoidfyTime.isBefore(remoteFileMoidfyTime)) {
      return SyncOperation.fetch;
    } else {
      return SyncOperation.noop;
    }
  }

  Future<void> syncFile(String localFilePath, String remoteFilePath) async {
    var syncOp = await checkFile(localFilePath, remoteFilePath);
    switch (syncOp) {
      case SyncOperation.fetch:
        await fetchFile(remoteFilePath, localFilePath);
        break;
      case SyncOperation.pull:
        await pullFile(localFilePath, remoteFilePath);
        break;
      case SyncOperation.noop:
        break;
    }  
  }
}
