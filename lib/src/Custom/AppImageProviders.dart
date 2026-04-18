import 'dart:io';

import 'package:flutter/painting.dart';

/// Avatares y miniaturas: limita píxeles decodificados (menos RAM y menos jank al scroll).
ImageProvider networkAvatarProvider(String url, {int logicalDiameter = 64}) {
  final d = (logicalDiameter * 2).clamp(64, 512);
  return ResizeImage(
    NetworkImage(url),
    width: d,
    height: d,
    allowUpscaling: false,
  );
}

ImageProvider fileAvatarProvider(File file, {int logicalDiameter = 64}) {
  final d = (logicalDiameter * 2).clamp(64, 512);
  return ResizeImage(
    FileImage(file),
    width: d,
    height: d,
    allowUpscaling: false,
  );
}
