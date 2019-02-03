class Config{
 static final  String stsserver="";
 static final String endpoint="";
 static final String cryptkey="";
 static final String bucket="";
 static final String key="";
 static final String callbackUrl="";
 static final String callbackHost="";
 ///支持 application/x-www-form-urlencoded 和application/json
 static final String callbackBodyType="application/json";
 static final String callbackBody="{\"j_bucket\":\${bucket},\"j_object\":\${object},\"j_etag\":\${etag},\"j_size\":\${size},\"j_mimeType\":\${mimeType},\"j_height\":\${imageInfo.height},\"j_width\":\${imageInfo.width},\"j_format\":\${imageInfo.format},\"j_memberId\":\${x:var1}}";
 static final String callbackVars="{\"x:var1\":\"123\"}";
}