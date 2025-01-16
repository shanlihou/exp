import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/utils.dart';
import '../types/file_item.dart';

class HomePage extends StatefulWidget {
  final String path;
  const HomePage({super.key, required this.path});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String currentPath = '';
  int selectedNum = 0;
  List<FileItem> fileItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.path != '') {
      currentPath = widget.path;
    } else {
      currentPath = Directory.current.path;
    }
    fileItems = loadFileItems(currentPath);
  }

  List<FileItem> loadFileItems(String path) {
    return Directory(path)
        .listSync()
        .map((e) => FileItem(e.path, false))
        .toList();
  }

  Widget buildCurrentPath() {
    List<String> pathParts;
    String separator;
    if (Platform.isWindows) {
      separator = '\\';
    } else {
      separator = '/';
    }
    pathParts = currentPath.split(separator);

    List<Widget> widgets = [];
    for (int i = 0; i < pathParts.length; i++) {
      String part = pathParts[i];
      widgets.add(Container(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
              onTap: () {
                List<String> newPathParts = pathParts.sublist(0, i + 1);
                String newPath = newPathParts.join(separator);
                tryToChangeNewPath(newPath);
              },
              child: Text(part))));
    }

    return Container(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: widgets,
        ),
      ),
    );
  }

  void testModify(String path) async {
    // 修改文件前几个字节
    try {
      RandomAccessFile file = await File(path).open(mode: FileMode.write);
      await file.writeFrom(Uint8List.fromList([97, 98, 99]));
      await file.close();
    } catch (e) {
      print('Error modifying file: $e');
    }
  }

  void tryToChangeNewPath(String path) {
    // 判断是否为文件夹, 不是则返回
    if (!Directory(path).existsSync()) {
      print('it is file new:$path');
      // testModify(path);
      return;
    }

    try {
      var newFileItems = loadFileItems(path);
      setState(() {
        fileItems = newFileItems;
        selectedNum = 0;
        currentPath = path;
        savePath();
      });
    } catch (e) {
      print('Error loading file items: $e');
    }
  }

  void savePath() {
    // 保存当前路径
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('currentPath', currentPath);
    });
  }

  void onSelect(int index, bool isSelected) {
    setState(() {
      fileItems[index].isSelected = isSelected;
      if (isSelected) {
        selectedNum++;
      } else {
        selectedNum--;
      }
    });
  }

  Widget buildBottomBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
            onPressed: () {
              for (int i = 0; i < fileItems.length; i++) {
                fileItems[i].isSelected = true;
              }
              setState(() {
                selectedNum = fileItems.length;
              });
            },
            child: const Text('全选')),
        TextButton(
            onPressed: () {
              for (int i = 0; i < fileItems.length; i++) {
                fileItems[i].isSelected = false;
              }
              setState(() {
                selectedNum = 0;
              });
            },
            child: const Text('取消')),
        TextButton(
            onPressed: () async {
              for (int i = 0; i < fileItems.length; i++) {
                if (fileItems[i].isSelected) {
                  await encryptFileAndRename(fileItems[i].path);
                }
              }
              setState(() {
                fileItems = loadFileItems(currentPath);
              });
            },
            child: const Text('加密')),
        TextButton(
            onPressed: () async {
              for (int i = 0; i < fileItems.length; i++) {
                if (fileItems[i].isSelected) {
                  await decryptFile(fileItems[i].path);
                }
              }
              setState(() {
                fileItems = loadFileItems(currentPath);
              });
            },
            child: const Text('解密')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Column(
        children: [
          buildCurrentPath(),
          Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) =>
                  fileItems[index].build(context, (path) {
                tryToChangeNewPath(path);
              }, (isSelected) => onSelect(index, isSelected)),
              itemCount: fileItems.length,
            ),
          ),
          if (selectedNum > 0) buildBottomBar(),
        ],
      ),
    );
  }
}
