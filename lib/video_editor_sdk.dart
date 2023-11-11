library video_editor_sdk;

import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_editor_sdk/editor_data.dart';
import 'package:video_editor_sdk/gen_util.dart';

class VideoEditorSdk {
  final GenUtil _genUtil = GenUtil();
  Future<String?> applyMultipleStickerOnVideo({
    required String inputVideoPath,
    required List<EditorData> editorData,
    String? outputVideoPath,
  }) async {
    for (int i = 0; i < editorData.length; i++) {
      await applyStickerOnVideo(
        inputVideoPath: inputVideoPath,
        stickerPath: editorData[i].stickerPath,
        fromDuration: editorData[i].from,
        toDuration: editorData[i].to,
        outputVideoPath: outputVideoPath,
        X: editorData[i].X,
        Y: editorData[i].Y,
      );
    }
    return outputVideoPath;
  }

  Future<String?> applyStickerOnVideo({
    required String inputVideoPath,
    required String stickerPath,
    required int fromDuration,
    required int toDuration,
    String? outputVideoPath,
    int? X,
    int? Y,
  }) async {
    if (outputVideoPath == null || outputVideoPath.isEmpty) {
      await _genUtil.createFolder();
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      outputVideoPath =
          '${documentsDirectory.path}/temp_files/${_genUtil.getRandomString(10)}.mp4';
    }

    String overlayCommand =
        '[0:v][1:v]overlay=${X ?? 0}:${Y ?? 0}:enable=\'between(t,$fromDuration,$toDuration)\'';

    final List<String> command = [
      '-i',
      inputVideoPath,
      '-i',
      stickerPath,
      '-filter_complex',
      overlayCommand,
      '-c:a',
      'copy',
      outputVideoPath,
    ];

    FFmpegSession session = await FFmpegKit.executeWithArguments(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      debugPrint("command succeeded");
      return outputVideoPath;
    } else if (ReturnCode.isCancel(returnCode)) {
      debugPrint("command cancelled");
      return null;
    } else {
      debugPrint("command failed!");
      return null;
    }
  }
}

