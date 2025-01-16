import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'const.dart';

Future<bool> getAndroidPermission() async {
  bool isGranted = await Permission.manageExternalStorage.isGranted;
  print('isGranted: $isGranted');

  if (!isGranted) {
    await Permission.manageExternalStorage.request();
  }
  isGranted = await Permission.manageExternalStorage.isGranted;
  print('isGranted2: $isGranted');

  final DeviceInfoPlugin info =
      DeviceInfoPlugin(); // import 'package:device_info_plus/device_info_plus.dart';
  final AndroidDeviceInfo androidInfo = await info.androidInfo;
  var strVersion = androidInfo.version.release;
  if (strVersion.contains('.')) {
    strVersion = strVersion.split('.').first;
  }
  final int androidVersion = int.parse(strVersion);

  if (androidVersion >= 13) {
    final request = await [
      Permission.videos,
      Permission.photos,
      Permission.audio,
    ].request(); //import 'package:permission_handler/permission_handler.dart';

    return request.values.every((status) => status == PermissionStatus.granted);
  } else {
    final status = await Permission.storage.request();
    return status.isGranted;
  }
}

Future<bool> getStoragePermission() async {
  bool ret = true;
  if (Platform.isAndroid) {
    ret = await getAndroidPermission();
  } else {
    // TODO: check iOS permission
    return ret;
  }

  return ret;
}

Future<bool> initDirectory() async {
  if (!await getStoragePermission()) {
    return false;
  }

  if (Platform.isAndroid) {
    var externalDir = await getExternalStorageDirectory();
    var applicationDir = await getApplicationDocumentsDirectory();
    Directory.current = externalDir ?? applicationDir;
  } else if (Platform.isWindows) {
    // var externalDir = await getExternalStorageDirectory();
    // var applicationDir = await getApplicationDocumentsDirectory();
    // Log.instance.d('external: $externalDir, application: $applicationDir');
  } else if (Platform.isIOS) {
    final tempDir = await getTemporaryDirectory();
    // Log.instance.d('Temporary directory: ${tempDir.path}');

    final appSupportDir = await getApplicationSupportDirectory();
    // Log.instance.d('Application support directory: ${appSupportDir.path}');

    final appDocumentsDir = await getApplicationDocumentsDirectory();
    // Log.instance.d('Application documents directory: ${appDocumentsDir.path}');
    Directory.current = appDocumentsDir;
  }

  // Log.instance.d('external: ${Directory.current}');
  return true;
}

List<int> getEncPassword() {
  List<int> encPwd = [];
  int zero = '0'.codeUnitAt(0);
  for (int i = 0; i < encPassword.length; i++) {
    int code = encPassword[i].codeUnitAt(0);
    encPwd.add(code - zero);
  }
  return encPwd;
}

Future<void> encryptFile(String path) async {
  // 先读取出前64字节, 加密后写入前64字节
  if (await isEncryptFile(path)) {
    return;
  }

  List<int> encPwd = getEncPassword();
  RandomAccessFile file = await File(path).open(mode: FileMode.append);
  await file.setPosition(0);
  Uint8List data = await file.read(64);
  for (int i = 0; i < data.length; i++) {
    int code = encPwd[i % encPwd.length];
    data[i] = (data[i] + code) % 256;
  }
  await file.setPosition(0);
  await file.writeFrom(data);

  await file.setPosition(await file.length());
  await file.writeFrom(encPwd);

  await file.close();
}

Future<void> encryptFileAndRename(String path) async {
  // 先读取出前64字节, 加密后写入前64字节
  if (await isEncryptFile(path)) {
    return;
  }

  await encryptFile(path);

  // 重命名文件
  String newPath = '$path.enc';
  await File(path).rename(newPath);
}

Future<bool> isEncryptFile(String path) async {
  List<int> encPwd = getEncPassword();
  RandomAccessFile file = await File(path).open(mode: FileMode.read);
  int fileLength = await file.length();
  await file.setPosition(fileLength - encPwd.length);
  Uint8List data = await file.read(encPwd.length);
  for (int i = 0; i < data.length; i++) {
    if (data[i] != encPwd[i]) {
      return false;
    }
  }

  return true;
}

Future<void> decryptFile(String path) async {
  // 先读取出前64字节, 解密后写入前64字节
  bool isEncrypt = await isEncryptFile(path);
  if (!isEncrypt) {
    return;
  }

  List<int> encPwd = getEncPassword();
  RandomAccessFile file = await File(path).open(mode: FileMode.append);
  await file.setPosition(0);
  Uint8List data = await file.read(64);
  for (int i = 0; i < data.length; i++) {
    int code = encPwd[i % encPwd.length];
    data[i] = (data[i] - code + 256) % 256;
  }
  await file.setPosition(0);
  await file.writeFrom(data);

  int fileLength = await file.length();
  await file.truncate(fileLength - encPwd.length);
  await file.close();

  // 重命名文件
  String newPath = path.replaceAll('.enc', '');
  await File(path).rename(newPath);
}
