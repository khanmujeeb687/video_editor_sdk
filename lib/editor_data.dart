class EditorData {
  String stickerPath;
  int from;
  int to;
  int X;
  int Y;

  EditorData({
    required this.stickerPath,
    required this.from,
    required this.to,
    this.X = 0,
    this.Y = 0,
  });
}
