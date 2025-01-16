import 'dart:io';

import 'package:flutter/material.dart';

class FileItem {
  final String path;
  bool isSelected;
  FileItem(this.path, this.isSelected);

  String basename() {
    if (Platform.isWindows) {
      return path.split('\\').last;
    } else {
      return path.split('/').last;
    }
  }

  Widget build(BuildContext context, ValueChanged<String> onTap,
      ValueChanged<bool> onSelect) {
    return Column(
      children: [
        Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                    onTap: () => onTap(path),
                    child: Text(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      basename(),
                    )),
                GestureDetector(
                  onTap: () => onSelect(!isSelected),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.circle,
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                )
              ],
            )),
        Container(
          height: 1,
          color: Colors.grey,
        )
      ],
    );
  }
}
