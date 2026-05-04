import 'dart:io';

import 'package:flutter/painting.dart';

/// Avatares: limita píxeles decodificados; [ResizeImagePolicy.fit] evita estirar si ancho y alto coinciden.
ImageProvider networkAvatarProvider(String url, {int logicalDiameter = 64}) {
  final d = (logicalDiameter * 2).clamp(64, 512);
  return ResizeImage(
    NetworkImage(url),
    width: d,
    height: d,
    policy: ResizeImagePolicy.fit,
    allowUpscaling: false,
  );
}

ImageProvider fileAvatarProvider(File file, {int logicalDiameter = 64}) {
  final d = (logicalDiameter * 2).clamp(64, 512);
  return ResizeImage(
    FileImage(file),
    width: d,
    height: d,
    policy: ResizeImagePolicy.fit,
    allowUpscaling: false,
  );
}
