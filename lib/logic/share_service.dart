import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Captures a [RepaintBoundary] widget as a PNG and opens the system share sheet.
class ShareService {
  ShareService._();

  /// [repaintKey] must be attached to a [RepaintBoundary] that is currently
  /// rendered in the widget tree.  [pixelRatio] defaults to 3× for a crisp
  /// share image on high-DPI screens.
  static Future<void> captureAndShare(
    GlobalKey repaintKey, {
    double pixelRatio = 3.0,
  }) async {
    final context = repaintKey.currentContext;
    if (context == null) return;

    final boundary =
        context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image    = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final dir  = await getTemporaryDirectory();
    final path = '${dir.path}/apex_share_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(path).writeAsBytes(byteData.buffer.asUint8List());

    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)]),
    );
  }
}
