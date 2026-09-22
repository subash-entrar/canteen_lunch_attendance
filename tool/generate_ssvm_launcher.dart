import 'dart:io';

import 'package:image/image.dart';

/// One-off helper to build a square launcher from the SSVM wordmark.
void main() {
  final logo =
      decodeImage(File('assets/images/ssvm_logo.jpg').readAsBytesSync())!;
  const size = 1024;
  final canvas = Image(width: size, height: size);
  fill(canvas, color: ColorRgb8(0x25, 0x45, 0x98));

  const platePad = 90;
  fillRect(
    canvas,
    x1: platePad,
    y1: size ~/ 2 - 140,
    x2: size - platePad,
    y2: size ~/ 2 + 140,
    color: ColorRgb8(255, 255, 255),
    radius: 48,
  );

  const maxW = size - platePad * 2 - 80;
  const maxH = 180;
  final scale = (maxW / logo.width < maxH / logo.height)
      ? maxW / logo.width
      : maxH / logo.height;
  final w = (logo.width * scale).round();
  final h = (logo.height * scale).round();
  final resized = copyResize(
    logo,
    width: w,
    height: h,
    interpolation: Interpolation.average,
  );
  compositeImage(
    canvas,
    resized,
    dstX: (size - w) ~/ 2,
    dstY: (size - h) ~/ 2,
  );

  File('assets/images/ssvm_launcher.png').writeAsBytesSync(encodePng(canvas));
  // ignore: avoid_print
  print('Wrote assets/images/ssvm_launcher.png ${size}x$size');
}
