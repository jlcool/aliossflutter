#import "AliossflutterPlugin.h"
#import <AliyunOSSiOS/OSSService.h>
#import "JKEncrypt.h"

NSString *endpoint = @"";
NSObject<FlutterPluginRegistrar> *registrar;
FlutterMethodChannel *channel;
OSSClient *oss ;

@implementation AliossflutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  channel = [FlutterMethodChannel
      methodChannelWithName:@"aliossflutter"
            binaryMessenger:[registrar messenger]];
  AliossflutterPlugin* instance = [[AliossflutterPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    
    if ([@"init" isEqualToString:call.method]) {         
            [self init:call result:result];
             return;
    }
    if ([@"upload" isEqualToString:call.method]) {
        [self update:call result:result];
        return;
    }else{
            result(FlutterMethodNotImplemented);
    }
  
}
- (void)init:(FlutterMethodCall*)call result:(FlutterResult)result {
    
    endpoint = call.arguments[@"endpoint"];
    // 构造请求访问您的业务server
    NSString *stsServer =call.arguments[@"stsserver"];
    NSString *crypt_key =call.arguments[@"cryptkey"];
    id<OSSCredentialProvider> credential1 = [[OSSFederationCredentialProvider alloc] initWithFederationTokenGetter:^OSSFederationToken * {
        
        
        NSURL * url = [NSURL URLWithString:stsServer];
        NSURLRequest * request = [NSURLRequest requestWithURL:url];
        OSSTaskCompletionSource * tcs = [OSSTaskCompletionSource taskCompletionSource];
        
        NSURLSession * session = [NSURLSession sharedSession];
        
        
        // 发送请求
        NSURLSessionTask * sessionTask = [session dataTaskWithRequest:request
                                          
                                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                        if (error) {
                                                            [tcs setError:error];
                                                            return;
                                                        }
                                                        [tcs setResult:data];
                                                    }];
        [sessionTask resume];
        // 需要阻塞等待请求返回
        [tcs.task waitUntilFinished];
        // 解析结果
        if (tcs.task.error) {
            NSLog(@"get token error: %@", tcs.task.error);
            NSDictionary *m1 = @{
                                 @"result": @"fail",
                                 @"message": [@"get token error: " stringByAppendingString:tcs.task.error]
                                 };
            result(m1);
            return nil;
        } else {
            // 返回数据是json格式，需要解析得到token的各个字段
            NSDictionary * object = [NSJSONSerialization JSONObjectWithData:tcs.task.result
                                                                    options:kNilOptions
                                                                      error:nil];
             JKEncrypt * en = [[JKEncrypt alloc]init];
            NSString *data=[en doDecEncryptStr:[object objectForKey:@"Data"]];
           NSLog(@"get token data: %@", data);
            NSDictionary *ossobject = [NSJSONSerialization JSONObjectWithData: [data dataUsingEncoding: NSUTF8StringEncoding]
                                                                    options:kNilOptions
                                                                      error:nil];
            NSLog(@"get token data: %@", [ossobject objectForKey:@"AccessKeyId"]);
            OSSFederationToken * token = [OSSFederationToken new];
            token.tAccessKey = [ossobject objectForKey:@"AccessKeyId"];
            token.tSecretKey = [ossobject objectForKey:@"AccessKeySecret"];
            token.tToken = [ossobject objectForKey:@"SecurityToken"];
            token.expirationTimeInGMTFormat = [ossobject objectForKey:@"Expiration"];
            NSLog(@"get token: %@", token);
            return token;
        }
    }];
    oss = [[OSSClient alloc] initWithEndpoint:endpoint credentialProvider:credential1];
    NSDictionary *m1 = @{
                         @"result": @"success"
                         };
    result(m1);
}
- (void)update:(FlutterMethodCall*)call result:(FlutterResult)result {
      NSString *bucket = call.arguments[@"bucket"];
      NSString * file = call.arguments[@"file"];
      NSString * key = call.arguments[@"key"];
    
    OSSPutObjectRequest * put = [OSSPutObjectRequest new];
    // 必填字段
    put.bucketName = bucket;
    put.objectKey = key;
    put.uploadingFileURL = [NSURL fileURLWithPath:file];
    // put.uploadingData = <NSData *>; // 直接上传NSData
    // 可选字段，可不设置
    put.uploadProgress = ^(int64_t bytesSent, int64_t totalByteSent, int64_t totalBytesExpectedToSend) {
        // 当前上传段长度、当前已经上传总长度、一共需要上传的总长度
        NSLog(@"%lld, %lld, %lld", bytesSent, totalByteSent, totalBytesExpectedToSend);
        NSDictionary *m1 = @{
                             @"currentSize":  [NSString stringWithFormat:@"%ll",totalByteSent],
                             @"totalSize": [NSString stringWithFormat:@"%ll",totalBytesExpectedToSend]
                             };
        [channel invokeMethod:@"onProgress" arguments:m1];
    };
    
    // 以下可选字段的含义参考： https://docs.aliyun.com/#/pub/oss/api-reference/object&PutObject
    // put.contentType = @"";
    // put.contentMd5 = @"";
    // put.contentEncoding = @"";
    // put.contentDisposition = @"";
    // put.objectMeta = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"value1", @"x-oss-meta-name1", nil]; // 可以在上传时设置元信息或者其他HTTP头部
    OSSTask * putTask = [oss putObject:put];
    [putTask continueWithBlock:^id(OSSTask *task) {
        if (!task.error) {
            NSLog(@"upload object success!");
        } else {
            NSLog(@"upload object failed, error: %@" , task.error);
        }
        return nil;
    }];
    // [putTask waitUntilFinished];
    // [put cancel];
    NSDictionary *m1 = @{
                         @"result": @"success"
                         };
    result(m1);
}
@end
