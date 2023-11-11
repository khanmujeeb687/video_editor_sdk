import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class ScreenshotUtil {

  @override
  Future<String?> captureScreenShotFromWidget(Widget widget,
      {Duration delay = const Duration(milliseconds: 50),
        double? pixelRatio,
        BuildContext? context,
        String? filename}) async {
    ///
    ///Retry counter
    ///
    int retryCounter = 3;
    bool isDirty = false;

    Widget child = widget;

    if (context != null) {
      ///
      ///Inherit Theme and MediaQuery of app
      ///
      ///
      child = InheritedTheme.captureAll(
        context,
        MediaQuery(data: MediaQuery.of(context), child: child),
      );
    }

    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();

    Size logicalSize =
        View.of(context!).physicalSize / View.of(context).devicePixelRatio;
    Size imageSize = View.of(context).physicalSize;

    assert(logicalSize.aspectRatio.toPrecision(5) ==
        imageSize.aspectRatio.toPrecision(5));

    final RenderView renderView = RenderView(
      view: View.of(context),
      child: RenderPositionedBox(
          alignment: Alignment.center, child: repaintBoundary),
      configuration: ViewConfiguration(
        size: logicalSize,
        devicePixelRatio: pixelRatio ?? 1.0,
      ),
    );

    final PipelineOwner pipelineOwner = PipelineOwner();
    final BuildOwner buildOwner = BuildOwner(
        focusManager: FocusManager(),
        onBuildScheduled: () {
          ///
          ///current render is dirty, mark it.
          ///
          isDirty = true;
        });

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final RenderObjectToWidgetElement<RenderBox> rootElement =
    RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: child,
        )).attachToRenderTree(
      buildOwner,
    );
    ////
    ///Render Widget
    ///
    ///

    buildOwner.buildScope(
      rootElement,
    );
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    ui.Image? image;

    do {
      ///
      ///Reset the dirty flag
      ///
      ///
      isDirty = false;

      image = await repaintBoundary.toImage(
          pixelRatio: pixelRatio ?? (imageSize.width / logicalSize.width));

      ///
      ///This delay shoud inceases with Widget tree Size
      ///

      await Future.delayed(delay);

      ///
      ///Check does this require rebuild
      ///
      ///
      if (isDirty) {
        ///
        ///Previous capture has been updated, re-render again.
        ///
        ///
        buildOwner.buildScope(
          rootElement,
        );
        buildOwner.finalizeTree();
        pipelineOwner.flushLayout();
        pipelineOwner.flushCompositingBits();
        pipelineOwner.flushPaint();
      }
      retryCounter--;

      ///
      ///retry untill capture is successfull
      ///
    } while (isDirty && retryCounter >= 0);

    final ByteData? byteData =
    await image.toByteData(format: ui.ImageByteFormat.png);

    String directory = !kIsWeb
        ? (await getApplicationDocumentsDirectory()).path
        : '/assets/db';
    await (image.toByteData(format: ui.ImageByteFormat.png));
    if (byteData != null) {
      var pngBytes = byteData.buffer.asUint8List();
      String path = '$directory/screenshot${filename ?? ""}.png';
      File imgFile = File(path);
      await imgFile.writeAsBytes(pngBytes);
      return path;
    } else {
      return null;
    }
  }
}
extension Ex on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}
