package com.jlcool.aliossflutter;

import android.util.Log;

import com.alibaba.sdk.android.oss.ClientConfiguration;
import com.alibaba.sdk.android.oss.ClientException;
import com.alibaba.sdk.android.oss.OSS;
import com.alibaba.sdk.android.oss.OSSClient;
import com.alibaba.sdk.android.oss.ServiceException;
import com.alibaba.sdk.android.oss.callback.OSSCompletedCallback;
import com.alibaba.sdk.android.oss.callback.OSSProgressCallback;
import com.alibaba.sdk.android.oss.common.auth.OSSAuthCredentialsProvider;
import com.alibaba.sdk.android.oss.common.auth.OSSCredentialProvider;
import com.alibaba.sdk.android.oss.internal.OSSAsyncTask;
import com.alibaba.sdk.android.oss.model.PutObjectRequest;
import com.alibaba.sdk.android.oss.model.PutObjectResult;


import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** AliossflutterPlugin */
public class AliossflutterPlugin implements MethodCallHandler {
  String endpoint;
  static Registrar registrar;
  static  MethodChannel channel;
  private static OSS oss;

  private AliossflutterPlugin(Registrar registrar){
    this.registrar = registrar;
  }
  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
   channel = new MethodChannel(registrar.messenger(), "aliossflutter");
    channel.setMethodCallHandler(new AliossflutterPlugin(registrar));
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    switch (call.method) {
      case "upload":
        upload(call,result);
        break;
      case "init":
        init(call,result);
        break;
      case "signurl":
        signUrl(call,result);
        break;
      default:
        result.notImplemented();
        break;
    }
  }
  private void init(final MethodCall call,final Result result) {
    endpoint = call.argument("endpoint");
    String stsServer =call.argument("stsserver");
    String crypt_key =call.argument("cryptkey");
    OSSAuthCredentialsProvider credentialProvider = new OSSAuthCredentialsProvider(stsServer);
    if(crypt_key!="") {
      credentialProvider.setDecoder(new AliDecoder(crypt_key,result));
    }
    ClientConfiguration conf = new ClientConfiguration();
    conf.setConnectionTimeout(15 * 1000); // 连接超时时间，默认15秒
    conf.setSocketTimeout(15 * 1000); // Socket超时时间，默认15秒
    conf.setMaxConcurrentRequest(5); // 最大并发请求数，默认5个
    conf.setMaxErrorRetry(2); // 失败后最大重试次数，默认2次
    oss = new OSSClient(registrar.activity().getApplicationContext(), endpoint, credentialProvider, conf);

  }
  private void upload(final MethodCall call,final Result _result) {
    final String bucket = call.argument("bucket");
    final String file = call.argument("file");
    final String key = call.argument("key");
    PutObjectRequest put = new PutObjectRequest(bucket, key, file);
    put.setProgressCallback(new OSSProgressCallback<PutObjectRequest>() {
      @Override
      public void onProgress(PutObjectRequest request, long currentSize, long totalSize) {
        Log.d("onProgress", "currentSize: " + currentSize + " totalSize: " + totalSize);
        Map<String,Long> m1=new HashMap<String, Long>();
        m1.put("currentSize",currentSize);
        m1.put("totalSize", totalSize);
        channel.invokeMethod("onProgress", m1);
      }
    });
if(oss==null){
  Map<String, String> m1 = new HashMap();
  m1.put("result", "fail");
  m1.put("message","请先初始化");
  _result.success(m1);
}else {
  OSSAsyncTask task = oss.asyncPutObject(put, new OSSCompletedCallback<PutObjectRequest, PutObjectResult>() {
            @Override
            public void onSuccess(PutObjectRequest request, PutObjectResult result) {
              Log.d("onSuccess", "onSuccess");
              Log.d("ETag", result.getETag());
              Log.d("RequestId", result.getRequestId());
              Map<String, String> m1 = new HashMap();
              m1.put("result", "success");
              m1.put("tag", result.getETag());
              m1.put("requestid", result.getRequestId());
              _result.success(m1);
            }

            @Override
            public void onFailure(PutObjectRequest request, ClientException clientExcepion, ServiceException serviceException) {
              // 请求异常
              if (clientExcepion != null) {
                // 本地异常如网络异常等
                clientExcepion.printStackTrace();
              }
              if (serviceException != null) {
                // 服务异常
                Log.e("ErrorCode", serviceException.getErrorCode());
                Log.e("RequestId", serviceException.getRequestId());
                Log.e("HostId", serviceException.getHostId());
                Log.e("RawMessage", serviceException.getRawMessage());

                Map<String, String> m1 = new HashMap();
                m1.put("result", "fail");
                m1.put("message",serviceException.getRawMessage());
                _result.success(m1);
              }
            }
          }

  );
}
  }
  private void signUrl(final MethodCall call,final Result _result)  {
    if(oss==null){
      Map<String, String> m1 = new HashMap();
      m1.put("result", "fail");
      m1.put("message","请先初始化");
      _result.success(m1);
    }else {
      try {
        final String bucket = call.argument("bucket");
        final String key = call.argument("key");
        final String type = call.argument("type");
        final String interval = call.argument("interval");
        Map<String, String> m1 = new HashMap();
        m1.put("result", "success");

        if (type == "0") {

          m1.put("url",oss.presignPublicObjectURL(bucket, key));

        } else {
          m1.put("url",oss.presignConstrainedObjectURL(bucket, key, Long.parseLong(interval)));
        }
        m1.put("test", "test");
        _result.success(m1);
      }catch (ClientException ex){
        Map<String, String> m1 = new HashMap();
        m1.put("result", "fail");
        m1.put("message",ex.toString());
        _result.success(m1);
      }
    }
  }
}
