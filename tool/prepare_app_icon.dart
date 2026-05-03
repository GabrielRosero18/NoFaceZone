// Recorta el icono desde app_icon_source.png: quita bandas negras y la
// viñeta/halo morado alrededor del squircle. Genera app_icon.png 1024 y
// app_icon_adaptive_fg.png (marco sólido #182247 para Android adaptive).
//
// Uso: dart run tool/prepare_app_icon.dart

import 'dart:io';

import 'package:image/image.dart';

const int _outSize = 1024;
/// Un poco más pequeño que el canvas adaptive = menos “zoom” del sistema
/// (no se comen las letras NFZ en máscaras redondas).
const int _adaptiveInner = 688;

bool _isBlackBar(Image img, int x, int y) {
  final p = img.getPixel(x, y);
  final r = p.r.toInt();
  final g = p.g.toInt();
  final b = p.b.toInt();
  return r < 16 && g < 16 && b < 16;
}

/// Recorta un poco por dentro del bbox para quitar aura morada exterior.
void _shrinkBboxToDropPurpleFringe(
  int imgW,
  int imgH,
  int left,
  int top,
  int right,
  int bottom, {
  required void Function(int l, int t, int r, int b) onResult,
}) {
  final cw = right - left + 1;
  final ch = bottom - top + 1;
  // Viñeta morada suave; si es mucho, se recortan letras — ~4.8% por lado.
  var inset = (cw < ch ? cw : ch) * 0.048;
  if (inset < 6) inset = 6;
  if (inset > cw * 0.35) inset = cw * 0.35;
  final inI = inset.round();

  var l = left + inI;
  var r = right - inI;
  var t = top + inI;
  var b = bottom - inI;
  if (l >= r - 24 || t >= b - 24) {
    // Demasiado agresivo: mitad del inset.
    final half = (inI * 0.5).round();
    l = left + half;
    r = right - half;
    t = top + half;
    b = bottom - half;
  }
  if (l >= r || t >= b) {
    onResult(left, top, right, bottom);
    return;
  }
  l = l.clamp(0, imgW - 1);
  r = r.clamp(0, imgW - 1);
  t = t.clamp(0, imgH - 1);
  b = b.clamp(0, imgH - 1);
  onResult(l, t, r, b);
}

void main() {
  final root = Directory.current.path;
  final srcPath = '$root/assets/icons/app_icon_source.png';
  final outMain = '$root/assets/icons/app_icon.png';
  final outAdaptive = '$root/assets/icons/app_icon_adaptive_fg.png';

  final bytes = File(srcPath).readAsBytesSync();
  final img = decodeImage(bytes);
  if (img == null) {
    stderr.writeln('No se pudo decodificar: $srcPath');
    exit(1);
  }

  var left = img.width;
  var right = 0;
  var top = img.height;
  var bottom = 0;

  for (var y = 0; y < img.height; y++) {
    for (var x = 0; x < img.width; x++) {
      if (!_isBlackBar(img, x, y)) {
        if (x < left) left = x;
        if (x > right) right = x;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
      }
    }
  }

  if (left >= right || top >= bottom) {
    stderr.writeln('No se detectó contenido; usa otra imagen.');
    exit(1);
  }

  _shrinkBboxToDropPurpleFringe(
    img.width,
    img.height,
    left,
    top,
    right,
    bottom,
    onResult: (l, t, r, b) {
      left = l;
      top = t;
      right = r;
      bottom = b;
    },
  );

  final cw = right - left + 1;
  final ch = bottom - top + 1;
  var side = cw > ch ? cw : ch;
  // Ligero “zoom out”: cuadrado ~2.2% más grande para que quepan las NFZ.
  final maxSide = img.width < img.height ? img.width : img.height;
  side = (side * 1.022).round().clamp(1, maxSide);

  final cx = (left + right) ~/ 2;
  final cy = (top + bottom) ~/ 2;
  var x0 = cx - side ~/ 2;
  var y0 = cy - side ~/ 2;
  if (x0 < 0) x0 = 0;
  if (y0 < 0) y0 = 0;
  if (x0 + side > img.width) x0 = img.width - side;
  if (y0 + side > img.height) y0 = img.height - side;
  if (side > img.width) {
    side = img.width;
    x0 = 0;
  }
  if (side > img.height) {
    side = img.height;
    y0 = 0;
  }

  var cropped = copyCrop(img, x: x0, y: y0, width: side, height: side);
  cropped = copyResize(
    cropped,
    width: _outSize,
    height: _outSize,
    interpolation: Interpolation.average,
  );

  File(outMain).writeAsBytesSync(encodePng(cropped));
  stdout.writeln('OK: $outMain (${cropped.width}x${cropped.height})');

  final bg = ColorRgb8(24, 34, 71);
  final adaptive = Image(width: _outSize, height: _outSize);
  fill(adaptive, color: bg);

  final inner = copyResize(
    cropped,
    width: _adaptiveInner,
    height: _adaptiveInner,
    interpolation: Interpolation.average,
  );
  final ox = (_outSize - inner.width) ~/ 2;
  final oy = (_outSize - inner.height) ~/ 2;
  compositeImage(adaptive, inner, dstX: ox, dstY: oy);

  File(outAdaptive).writeAsBytesSync(encodePng(adaptive));
  stdout.writeln('OK: $outAdaptive (marco #182247)');
}
