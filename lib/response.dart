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
    String servercallback;
  UploadResponse({this.success, this.key,this.msg,this.servercallback});
}
class DownloadResponse {
    bool success;
    String path;
    String msg;
  DownloadResponse({this.success, this.path,this.msg});
}
class DeleteResponse {
    bool success;
    String key;
  DeleteResponse({this.success,this.key});
}
