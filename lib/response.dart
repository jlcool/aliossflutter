class ProgressResponse {
   final double currentSize  ;
   final double totalSize;

  ProgressResponse({this.currentSize,this.totalSize});

  double getProgress() {
    // TODO: implement toString
    return  currentSize/totalSize;
  }

}
