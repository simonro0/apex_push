import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Captures a [RepaintBoundary] widget as a PNG and opens the system share sheet.
class ShareService {
  ShareService._();

  // ── Capture helpers ────────────────────────────────────────────────────────

  /// Captures [repaintKey]'s widget as a PNG and saves it to the temp dir.
  ///
  /// Returns the file path on success, or `null` if the widget is not
  /// attached / the capture fails.  Does NOT open a share sheet — use
  /// [shareFile] or [captureAndShare] for that.
  static Future<String?> captureToFile(
    GlobalKey repaintKey, {
    double pixelRatio = 3.0,
  }) async {
    final ctx = repaintKey.currentContext;
    if (ctx == null) return null;

    final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image    = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final dir  = await getTemporaryDirectory();
    final path = '${dir.path}/apex_share_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(path).writeAsBytes(byteData.buffer.asUint8List());
    return path;
  }

  /// Opens the system share sheet for an already-captured [filePath].
  static Future<void> shareFile(String filePath, {String mimeType = 'image/png'}) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(filePath, mimeType: mimeType)]),
    );
  }

  // ── Combined helper ────────────────────────────────────────────────────────

  /// [repaintKey] must be attached to a [RepaintBoundary] that is currently
  /// rendered in the widget tree.  [pixelRatio] defaults to 3× for a crisp
  /// share image on high-DPI screens.
  static Future<void> captureAndShare(
    GlobalKey repaintKey, {
    double pixelRatio = 3.0,
  }) async {
    final path = await captureToFile(repaintKey, pixelRatio: pixelRatio);
    if (path == null) return;
    await shareFile(path);
  }
}
