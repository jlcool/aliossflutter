package com.jlcool.aliossflutter;

import android.app.Activity;
import android.util.Log;

import com.alibaba.sdk.android.oss.ClientConfiguration;
import com.alibaba.sdk.android.oss.ClientException;
import com.alibaba.sdk.android.oss.OSS;
import com.alibaba.sdk.android.oss.OSSClient;
import com.alibaba.sdk.android.oss.ServiceException;
import com.alibaba.sdk.android.oss.callback.OSSCompletedCallback;
import com.alibaba.sdk.android.oss.callback.OSSProgressCallback;
import com.alibaba.sdk.android.oss.common.OSSConstants;
import com.alibaba.sdk.android.oss.common.OSSLog;
import com.alibaba.sdk.android.oss.common.auth.OSSAuthCredentialsProvider;
import com.alibaba.sdk.android.oss.common.auth.OSSCredentialProvider;
import com.alibaba.sdk.android.oss.common.auth.OSSCustomSignerCredentialProvider;
import com.alibaba.sdk.android.oss.common.auth.OSSFederationCredentialProvider;
import com.alibaba.sdk.android.oss.common.auth.OSSFederationToken;
import com.alibaba.sdk.android.oss.common.utils.IOUtils;
import com.alibaba.sdk.android.oss.common.utils.OSSUtils;
import com.alibaba.sdk.android.oss.internal.OSSAsyncTask;
import com.alibaba.sdk.android.oss.model.DeleteObjectRequest;
import com.alibaba.sdk.android.oss.model.DeleteObjectResult;
import com.alibaba.sdk.android.oss.model.GeneratePresignedUrlRequest;
import com.alibaba.sdk.android.oss.model.GetObjectRequest;
import com.alibaba.sdk.android.oss.model.GetObjectResult;
import com.alibaba.sdk.android.oss.model.HeadObjectRequest;
import com.alibaba.sdk.android.oss.model.HeadObjectResult;
import com.alibaba.sdk.android.oss.model.PutObjectRequest;
import com.alibaba.sdk.android.oss.model.PutObjectResult;


import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Handler;

import javax.crypto.BadPaddingException;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.NoSuchPaddingException;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * AliossflutterPlugin
 */
public class AliossflutterPlugin implements MethodCallHandler {
    String endpoint;
    static Registrar registrar;
    private final Activity activity;

    static MethodChannel channel;
    Result _result;
    MethodCall _call;
    private static OSS oss;

    private AliossflutterPlugin(Registrar registrar, Activity activity) {
        this.registrar = registrar;
        this.activity=activity;
    }

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        channel = new MethodChannel(registrar.messenger(), "aliossflutter");
        channel.setMethodCallHandler(new AliossflutterPlugin(registrar, registrar.activity()));
    }
    @Override
    public void onMethodCall(MethodCall call, Result result) {
        _result = result;
        _call = call;

        switch (call.method) {
            case "upload":
                upload(call);
                break;
            case "download":
                download(call);
                break;
            case "init":
                init();
            case "secretInit":
                secretInit();
                break;
            case "signurl":
                signUrl(call);
                break;
            case "des":
                des(call);
                break;
            case "aes":
                aes(call);
                break;
            case "delete":
                delete(call);
                break;
            case "doesObjectExist":
                doesObjectExist(call);
                break;
            case "asyncHeadObject":
                asyncHeadObject(call);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void secretInit() {
        endpoint = _call.argument("endpoint");
        final String accessKeyId = _call.argument("accessKeyId");
        final String accessKeySecret = _call.argument("accessKeySecret");
        final String _id = _call.argument("id");

        final Map<String, String> m1 = new HashMap();
        m1.put("result", "success");
        m1.put("id", _id);

        final OSSCustomSignerCredentialProvider credentialProvider = new OSSCustomSignerCredentialProvider() {
            @Override
            public String signContent(String content) {
                return OSSUtils.sign(accessKeyId, accessKeySecret, content);
            }
        };
        oss = new OSSClient(registrar.context(), endpoint, credentialProvider);
        channel.invokeMethod("onInit", m1);
    }

    private void asyncHeadObject(final MethodCall call){
        final String bucket = call.argument("bucket");
        final String key = call.argument("key");
        final String _id = call.argument("id");

        // 创建同步获取文件元信息请求。
        HeadObjectRequest head = new HeadObjectRequest(bucket, key);

// 获取文件元信息。
        oss.asyncHeadObject(head, new OSSCompletedCallback<HeadObjectRequest, HeadObjectResult>() {
            @Override
            public void onSuccess(HeadObjectRequest request, HeadObjectResult result) {
                final Map<String, Object> m1 = new HashMap();
                m1.put("key", key);
                m1.put("result",true);
                m1.put("lastModified",result.getMetadata().getLastModified().getTime());
                m1.put("id", _id);
                activity.runOnUiThread(
                        new Runnable() {
                            @Override
                            public void run() {
                                channel.invokeMethod("onHeadObject", m1);
                            }
                        });
            }

            @Override
            public void onFailure(HeadObjectRequest request, ClientException clientExcepion, ServiceException serviceException) {
                // 请求异常。
                if (clientExcepion != null) {
                    // 本地异常，如网络异常等。
                    clientExcepion.printStackTrace();
                }
                if (serviceException != null) {

                }
                // 服务异常。
                final Map<String, Object> m1 = new HashMap();
                m1.put("key", key);
                m1.put("result", false);
                m1.put("lastModified",0);
                m1.put("id", _id);
                activity.runOnUiThread(
                        new Runnable() {
                            @Override
                            public void run() {
                                channel.invokeMethod("onHeadObject", m1);
                            }
                        });
            }
        });
    }

    private void init() {
        endpoint = _call.argument("endpoint");
        final String stsServer = _call.argument("stsserver");
        final String crypt_key = _call.argument("cryptkey");
        final String crypt_type = _call.argument("crypttype");
        final String _id = _call.argument("id");
        final OSSCredentialProvider credentialProvider = new OSSFederationCredentialProvider() {
            @Override
            public OSSFederationToken getFederationToken() {
                try {
                    URL stsUrl = new URL(stsServer);
                    HttpURLConnection conn = (HttpURLConnection) stsUrl.openConnection();
                    InputStream input = conn.getInputStream();
                    String jsonText = IOUtils.readStreamAsString(input, OSSConstants.DEFAULT_CHARSET_NAME);
                    JSONObject jsonObj = new JSONObject(jsonText);
                    if (!"".equals(crypt_key) && crypt_key != null) {
                        String dec = jsonObj.getString("Data");
                        if ("aes".equals(crypt_type)) {
                            jsonText = AESCipher.aesDecryptString(dec, crypt_key);
                        } else {
                            SecretUtils.PASSWORD_CRYPT_KEY = crypt_key;
                            jsonText = new String(SecretUtils.decryptMode(dec));
                        }
                    }
                    JSONObject jsonObjs = new JSONObject(jsonText);
//                    {
//                        "StatusCode": 200,
//                            "AccessKeyId":"STS.iA645eTOXEqP3cg3VeHf",
//                            "AccessKeySecret":"rV3VQrpFQ4BsyHSAvi5NVLpPIVffDJv4LojUBZCf",
//                            "Expiration":"2015-11-03T09:52:59Z",
//                            "SecurityToken":"CAES7QIIARKAAZPlqaN9ILiQZPS+JDkS/GSZN45RLx4YS/p3OgaUC+oJl3XSlbJ7StKpQ...."
//                      }
                    String ak = jsonObjs.getString("AccessKeyId");
                    String sk = jsonObjs.getString("AccessKeySecret");
                    String token = jsonObjs.getString("SecurityToken");
                    String expiration = jsonObjs.getString("Expiration");
                    return new OSSFederationToken(ak, sk, token, expiration);
                } catch (Exception e) {
                    e.printStackTrace();
                }
                return null;
            }
        };
        final ClientConfiguration conf = new ClientConfiguration();
        conf.setConnectionTimeout(15 * 1000); // 连接超时时间，默认15秒
        conf.setSocketTimeout(15 * 1000); // Socket超时时间，默认15秒
        conf.setMaxConcurrentRequest(5); // 最大并发请求数，默认5个
        conf.setMaxErrorRetry(2); // 失败后最大重试次数，默认2次

                oss = new OSSClient(registrar.context(), endpoint, credentialProvider, conf);
                final Map<String, String> m1 = new HashMap();
                m1.put("result", "success");
                m1.put("id", _id);
        activity.runOnUiThread(
                new Runnable() {
                    @Override
                    public void run() {
                        channel.invokeMethod("onInit", m1);
                    }
                });
    }

    private void upload(final MethodCall call) {
        final String key = call.argument("key");
        final String _id = call.argument("id");
        if (oss == null) {
            final Map<String, String> m1 = new HashMap();
            m1.put("result", "fail");
            m1.put("id", _id);
            m1.put("key", key);
            m1.put("message", "请先初始化");
            channel.invokeMethod("onUpload", m1);

        } else {
            final String bucket = call.argument("bucket");
            final String file = call.argument("file");
            final String _callbackUrl = call.argument("callbackUrl");
            final String _callbackHost = call.argument("callbackHost");
            final String _callbackBodyType = call.argument("callbackBodyType");
            final String _callbackBody = call.argument("callbackBody");
            final String _callbackVars = call.argument("callbackVars");
            PutObjectRequest put = new PutObjectRequest(bucket, key, file);
            put.setProgressCallback(new OSSProgressCallback<PutObjectRequest>() {
                @Override
                public void onProgress(PutObjectRequest request, long currentSize, long totalSize) {
                    Log.d("onProgress", "currentSize: " + currentSize + " totalSize: " + totalSize);
                    final Map<String, String> m1 = new HashMap<String, String>();
                    m1.put("key", key);
                    m1.put("currentSize", String.valueOf(currentSize));
                    m1.put("totalSize", String.valueOf(totalSize));
                    m1.put("id", _id);
                    activity.runOnUiThread(
                            new Runnable() {
                                @Override
                                public void run() {
                                    channel.invokeMethod("onProgress", m1);
                                }
                            });
                }
            });
            if (_callbackUrl != "" && _callbackUrl != null) {

                try {
                    JSONObject jsonObjs = new JSONObject(_callbackVars);
                    put.setCallbackParam(new HashMap<String, String>() {
                        {
                            put("callbackUrl", _callbackUrl);
                            put("callbackHost", _callbackHost);
                            put("callbackBodyType", _callbackBodyType);
                            put("callbackBody", _callbackBody);
                            //{"bucket":${bucket},"object":${object},"etag":${etag},"size":${size},"mimeType":${mimeType},"imageInfo.height":${imageInfo.height},"imageInfo.width":${imageInfo.width},"imageInfo.format":${imageInfo.format}}
                        }
                    });
                    HashMap<String, String> _vars = new HashMap();
                    for (int i = 0; i < jsonObjs.names().length(); i++) {
                        _vars.put(jsonObjs.names().getString(i), jsonObjs.getString(jsonObjs.names().getString(i)));
                    }
                    put.setCallbackVars(_vars);
                } catch (JSONException e) {
                    final Map<String, String> m1 = new HashMap();
                    m1.put("result", "fail");
                    m1.put("id", _id);
                    m1.put("key", key);
                    m1.put("message", "callbackVars 格式错误");
                    activity.runOnUiThread(
                            new Runnable() {
                                @Override
                                public void run() {
                                    channel.invokeMethod("onUpload", m1);
                                }
                            });
                    return;
                }

            }
            OSSAsyncTask task = oss.asyncPutObject(put, new OSSCompletedCallback<PutObjectRequest, PutObjectResult>() {
                        @Override
                        public void onSuccess(PutObjectRequest request, PutObjectResult result) {
                            Log.d("onSuccess", "onSuccess");
                            Log.d("ETag", result.getETag());
                            Log.d("RequestId", result.getRequestId());

                            String serverCallbackReturnJson = result.getServerCallbackReturnBody();
                            final Map<String, String> m1 = new HashMap();
                            m1.put("result", "success");
                            m1.put("tag", result.getETag());
                            m1.put("id", _id);
                            m1.put("key", key);
                            m1.put("servercallback", serverCallbackReturnJson);
                            m1.put("requestid", result.getRequestId());
                            activity.runOnUiThread(
                                    new Runnable() {
                                        @Override
                                        public void run() {
                                            channel.invokeMethod("onUpload", m1);
                                        }
                                    });
                        }

                        @Override
                        public void onFailure(PutObjectRequest request, ClientException clientExcepion, ServiceException serviceException) {
                            // 请求异常
                            final Map<String, String> m1 = new HashMap();
                            if (clientExcepion != null) {
                                // 本地异常如网络异常等
                                clientExcepion.printStackTrace();
                                m1.put("result", "fail");
                                m1.put("id", _id);
                                m1.put("key", key);
                                m1.put("message", clientExcepion.getMessage());
                            }
                            if (serviceException != null) {
                                // 服务异常
                                Log.e("ErrorCode", serviceException.getErrorCode());
                                Log.e("RequestId", serviceException.getRequestId());
                                Log.e("HostId", serviceException.getHostId());
                                Log.e("RawMessage", serviceException.getRawMessage());


                                m1.put("result", "fail");
                                m1.put("id", _id);
                                m1.put("key", key);
                                m1.put("message", serviceException.getRawMessage());
                            }
                            activity.runOnUiThread(
                                    new Runnable() {
                                        @Override
                                        public void run() {
                                            channel.invokeMethod("onUpload", m1);
                                        }
                                    });
                        }
                    }
            );
        }
    }

    private void download(final MethodCall call) {
        final String _key = call.argument("key");
        final String _id = call.argument("id");
        if (oss == null) {
            Map<String, String> m1 = new HashMap();
            m1.put("result", "fail");
            m1.put("id", _id);
            m1.put("key", _key);
            m1.put("message", "请先初始化");
            channel.invokeMethod("onDownload", m1);
        } else {
//      try {
            final String _bucket = call.argument("bucket");

            String process = call.argument("process");

            final String _path = call.argument("path");
            GetObjectRequest get = new GetObjectRequest(_bucket, _key);
            if (!"".equals(process)) {
                get.setxOssProcess(process);
            }
//设置下载进度回调
            get.setProgressListener(new OSSProgressCallback<GetObjectRequest>() {
                @Override
                public void onProgress(GetObjectRequest request, long currentSize, long totalSize) {
                    final Map<String, Object> m1 = new HashMap();
                    m1.put("currentSize", currentSize);
                    m1.put("totalSize", totalSize);
                    m1.put("key", _key);
                    activity.runOnUiThread(
                            new Runnable() {
                                @Override
                                public void run() {
                                    channel.invokeMethod("onProgress", m1);
                                }
                            });
                }
            });
            OSSAsyncTask task = oss.asyncGetObject(get, new OSSCompletedCallback<GetObjectRequest, GetObjectResult>() {
                @Override
                public void onSuccess(GetObjectRequest request, GetObjectResult result) {
                    // 请求成功
                    InputStream inputStream = result.getObjectContent();
                    byte[] buffer = new byte[2048];
                    int len;
                    OutputStream os = null;
                    try {
                        os = new FileOutputStream(_path);
                        while ((len = inputStream.read(buffer)) != -1) {
                            os.write(buffer, 0, len);
                        }
                        final Map<String, String> m1 = new HashMap();
                        m1.put("result", "success");
                        m1.put("id", _id);
                        m1.put("path", _path);
                        m1.put("key", _key);
                        activity.runOnUiThread(
                                new Runnable() {
                                    @Override
                                    public void run() {
                                        channel.invokeMethod("onDownload", m1);
                                    }
                                });
                        os.flush();
                    } catch (IOException e) {
                        e.printStackTrace();
                        final Map<String, String> m1 = new HashMap();
                        m1.put("result", "fail");
                        m1.put("id", _id);
                        m1.put("path", _path);
                        m1.put("key", _key);
                        m1.put("message", e.getMessage());
                        activity.runOnUiThread(
                                new Runnable() {
                                    @Override
                                    public void run() {
                                        channel.invokeMethod("onDownload", m1);
                                    }
                                });
                    } finally {
                        try {
                            os.close();
                            inputStream.close();
                        } catch (IOException e) {
                            e.printStackTrace();
                        }
                    }
                }

                @Override
                public void onFailure(GetObjectRequest request, ClientException clientExcepion, ServiceException serviceException) {
                    // 请求异常
                    if (clientExcepion != null) {
                        // 本地异常如网络异常等
                        clientExcepion.printStackTrace();
                        final Map<String, String> m1 = new HashMap();
                        m1.put("result", "fail");
                        m1.put("id", _id);
                        m1.put("path", _path);
                        m1.put("key", _key);
                        m1.put("message", clientExcepion.getMessage());
                        activity.runOnUiThread(
                                new Runnable() {
                                    @Override
                                    public void run() {
                                        channel.invokeMethod("onDownload", m1);
                                    }
                                });
                    }
                    if (serviceException != null) {
                        // 服务异常
                        Log.e("ErrorCode", serviceException.getErrorCode());
                        Log.e("RequestId", serviceException.getRequestId());
                        Log.e("HostId", serviceException.getHostId());
                        Log.e("RawMessage", serviceException.getRawMessage());
                        final Map<String, String> m1 = new HashMap();
                        m1.put("result", "fail");
                        m1.put("id", _id);
                        m1.put("path", _path);
                        m1.put("key", _key);
                        m1.put("message", String.valueOf(serviceException.getStatusCode()));
                        activity.runOnUiThread(
                                new Runnable() {
                                    @Override
                                    public void run() {
                                        channel.invokeMethod("onDownload", m1);
                                    }
                                });
                    }
                }
            });
        }
    }

    //删除
    private void delete(final MethodCall call) {
        final String _key = call.argument("key");
        final String _id = call.argument("id");
        if (oss == null) {
            Map<String, String> m1 = new HashMap();
            m1.put("result", "fail");
            m1.put("id", _id);
            m1.put("message", "请先初始化");
            channel.invokeMethod("onDelete", m1);
        } else {
            final String _bucket = call.argument("bucket");
// 创建删除请求
            DeleteObjectRequest delete = new DeleteObjectRequest(_bucket, _key);
// 异步删除
            OSSAsyncTask deleteTask = oss.asyncDeleteObject(delete, new OSSCompletedCallback<DeleteObjectRequest, DeleteObjectResult>() {
                @Override
                public void onSuccess(DeleteObjectRequest request, DeleteObjectResult result) {
                    final Map<String, String> m1 = new HashMap();
                    m1.put("result", "success");
                    m1.put("id", _id);
                    m1.put("key", _key);
                    activity.runOnUiThread(
                            new Runnable() {
                                @Override
                                public void run() {
                                    channel.invokeMethod("onDelete", m1);
                                }
                            });
                }

                @Override
                public void onFailure(DeleteObjectRequest request, ClientException clientExcepion, ServiceException serviceException) {
                    // 请求异常
                    if (clientExcepion != null) {
                        final Map<String, String> m1 = new HashMap();
                        m1.put("result", "fail");
                        m1.put("id", _id);
                        m1.put("key", _key);
                        m1.put("message", clientExcepion.getMessage());
                        activity.runOnUiThread(
                                new Runnable() {
                                    @Override
                                    public void run() {
                                        channel.invokeMethod("onDelete", m1);
                                    }
                                });
                    }
                    if (serviceException != null) {
                        // 服务异常
                        Log.e("ErrorCode", serviceException.getErrorCode());
                        Log.e("RequestId", serviceException.getRequestId());
                        Log.e("HostId", serviceException.getHostId());
                        Log.e("RawMessage", serviceException.getRawMessage());
                        final Map<String, String> m1 = new HashMap();
                        m1.put("result", "fail");
                        m1.put("id", _id);
                        m1.put("key", _key);
                        m1.put("message", String.valueOf(serviceException.getStatusCode()));
                        activity.runOnUiThread(
                                new Runnable() {
                                    @Override
                                    public void run() {
                                        channel.invokeMethod("onDelete", m1);
                                    }
                                });
                    }
                }

            });
        }
    }

    //签名url
    private void signUrl(final MethodCall call) {
        final String _id = call.argument("id");
        final String _key = call.argument("key");
        if (oss == null) {
            Map<String, String> m1 = new HashMap();
            m1.put("result", "fail");
            m1.put("id", _id);
            m1.put("_key", _key);
            m1.put("message", "请先初始化");
            channel.invokeMethod("onSign", m1);
        } else {
//      try {
            final String _bucket = call.argument("bucket");

            final String _type = call.argument("type");

            final Long _interval = Long.parseLong(call.argument("interval").toString());
            final Map<String, String> m1 = new HashMap();

            if ("0".equals(_type)) {
                m1.put("result", "success");
                m1.put("id", _id);
                m1.put("key", _key);
                m1.put("url", oss.presignPublicObjectURL(_bucket, _key));
                activity.runOnUiThread(
                        new Runnable() {
                            @Override
                            public void run() {
                                channel.invokeMethod("onSign", m1);
                            }
                        });
            } else if ("1".equals(_type)) {
                new Thread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            final Map<String, String> m1 = new HashMap();
                            m1.put("result", "success");
                            String url = oss.presignConstrainedObjectURL(_bucket, _key, _interval);
                            m1.put("url", url);
                            m1.put("key", _key);
                            m1.put("id", _id);
                            activity.runOnUiThread(
                                    new Runnable() {
                                        @Override
                                        public void run() {
                                            channel.invokeMethod("onSign", m1);
                                        }
                                    });
                        } catch (ClientException e) {
                            final Map<String, String> m1 = new HashMap();
                            m1.put("result", "fail");
                            m1.put("message", e.toString());
                            m1.put("key", _key);
                            m1.put("id", _id);
                            activity.runOnUiThread(
                                    new Runnable() {
                                        @Override
                                        public void run() {
                                            channel.invokeMethod("onSign", m1);
                                        }
                                    });
                        }
                    }
                }).start();
            } else {
                m1.put("result", "fail");
                m1.put("key", _key);
                m1.put("message", "签名类型错误");
                m1.put("id", _id);
                activity.runOnUiThread(
                        new Runnable() {
                            @Override
                            public void run() {
                                channel.invokeMethod("onSign", m1);
                            }
                        });
            }

        }
    }


    private void doesObjectExist(final MethodCall call) {
        final String _key = call.argument("key");
        final String _bucket = call.argument("bucket");
        if (oss == null) {
            _result.error("err", "请先初始化", null);
        } else {
            try {
                if (oss.doesObjectExist(_bucket, _key)) {
                    _result.success(true);
                } else {
                    _result.success(false);
                }
            } catch (ClientException e) {
                _result.error("err", e.getMessage(), null);
            } catch (ServiceException e) {
                Log.e("ErrorCode", e.getErrorCode());
                Log.e("RequestId", e.getRequestId());
                Log.e("HostId", e.getHostId());
                Log.e("RawMessage", e.getRawMessage());
                _result.error("err", e.getMessage(), null);
            }
        }
    }

    //3des 加密
    private void des(final MethodCall call) {
        final String _key = call.argument("key");
        //encrypt or decrypt
        final String _type = call.argument("type");
        final String _data = call.argument("data");
        SecretUtils.PASSWORD_CRYPT_KEY = _key;
        String _res = "";
        if (_type.equals("encrypt")) {
            _res = new String(SecretUtils.encryptMode(_data));
        } else if (_type.equals("decrypt")) {
            _res = new String(SecretUtils.decryptMode(_data));
        }
        _result.success(_res.replaceAll("\r|\n", ""));
    }

    //aes 加密
    private void aes(final MethodCall call) {
        final String _key = call.argument("key");
        //encrypt or decrypt
        final String _type = call.argument("type");
        final String _data = call.argument("data");
        SecretUtils.PASSWORD_CRYPT_KEY = _key;
        String _res = "";
        try {
            if (_type.equals("encrypt")) {
                _res = new String(AESCipher.aesEncryptString(_data, _key));
            } else if (_type.equals("decrypt")) {
                _res = new String(AESCipher.aesDecryptString(_data, _key));
            }
        } catch (Exception ex) {

        }
        _result.success(_res);
    }
}
