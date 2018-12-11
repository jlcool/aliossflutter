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
  String msg;
  SignResponse({this.success, this.url,this.msg});
}
class UploadResponse {
    bool success;
    String key;
    String msg;
  UploadResponse({this.success, this.key,this.msg});
}
class DownloadResponse {
    bool success;
    String path;
    String msg;
  DownloadResponse({this.success, this.path,this.msg});
}
