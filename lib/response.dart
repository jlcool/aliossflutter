class ProgressResponse {
  final double currentSize;
  final String key;
  final double totalSize;

  ProgressResponse({this.currentSize, this.totalSize,this.key});

  double getProgress() {
    // TODO: implement toString
    return currentSize / totalSize;
  }
}
class SignResponse {
  bool success;
  String url;
  String key;
  String msg;
  SignResponse({this.success, this.url,this.msg,this.key});
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
    String key;
    String msg;
  DownloadResponse({this.success, this.path,this.msg,this.key});
}
class DeleteResponse {
    bool success;
    String key;
  DeleteResponse({this.success,this.key});
}
class HeadObjectResponse {
  bool success;
  int lastModified;
  String key;
  HeadObjectResponse({this.success,this.lastModified,this.key});
}