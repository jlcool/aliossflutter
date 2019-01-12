class ProgressResponse {
  final double currentSize;

  final double totalSize;

  ProgressResponse({this.currentSize, this.totalSize});

  double getProgress() {
    // TODO: implement toString
    return currentSize / totalSize;
  }
}
class SignResponse {
  bool success;
  String url;
  SignResponse({this.success, this.url});
}
class UploadResponse {
    bool success;
    String key;
  UploadResponse({this.success, this.key});
}
class DownloadResponse {
    bool success;
    String path;
  DownloadResponse({this.success, this.path});
}
class DeleteResponse {
    bool success;
    String key;
  DeleteResponse({this.success,this.key});
}
