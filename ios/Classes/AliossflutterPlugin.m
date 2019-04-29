#import "AliossflutterPlugin.h"
#import <AliyunOSSiOS/OSSService.h>
#import "JKEncrypt.h"
#import "AESCipher.h"

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
    }else if ([@"upload" isEqualToString:call.method]) {
        [self update:call result:result];
        return;
    }
    else if ([@"download" isEqualToString:call.method]) {
        [self download:call result:result];
        return;
    }else if ([@"signurl" isEqualToString:call.method]) {
        [self signUrl:call result:result];
        return;
    }else if ([@"des" isEqualToString:call.method]) {
        [self des:call result:result];
        return;
    }else if ([@"delete" isEqualToString:call.method]) {
        [self delete:call result:result];
        return;
    }else if ([@"doesObjectExist" isEqualToString:call.method]) {
        [self doesObjectExist:call result:result];
        return;
    }else {
        result(FlutterMethodNotImplemented);
    }
}
- (void)init:(FlutterMethodCall*)call result:(FlutterResult)result {
    
    endpoint = call.arguments[@"endpoint"];
    NSString *stsServer =call.arguments[@"stsserver"];
    NSString *crypt_key =call.arguments[@"cryptkey"];
    NSString *crypt_type =call.arguments[@"crypttype"];
    NSString *_id =call.arguments[@"id"];
    
    id<OSSCredentialProvider> credential1 = [[OSSFederationCredentialProvider alloc] initWithFederationTokenGetter:^OSSFederationToken * {
        
        NSLog(@"init credential1");
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
            return nil;
        } else {
            // 返回数据是json格式，需要解析得到token的各个字段
            
            NSData *data=tcs.task.result;
            
            
            if(![crypt_key isEqualToString:@""]){
                NSDictionary * object = [NSJSONSerialization JSONObjectWithData:data
                                                                        options:kNilOptions
                                                                          error:nil];
                if([crypt_type isEqualToString:@"aes"]){
                    data=[aesDecryptString([object objectForKey:@"Data"],crypt_key) dataUsingEncoding:NSUTF8StringEncoding];
                    NSLog(@"get token aes: %@", data);
                }else{
                    JKEncrypt * en = [[JKEncrypt alloc]init];
                    data=[[en doDecEncryptStr:[object objectForKey:@"Data"] key:crypt_key] dataUsingEncoding:NSUTF8StringEncoding];
                    NSLog(@"get token 3des: %@", data);
                }
            }
            
            NSDictionary *ossobject = [NSJSONSerialization JSONObjectWithData: data
                                                                      options:kNilOptions
                                                                        error:nil];
            OSSFederationToken * token = [OSSFederationToken new];
            token.tAccessKey = [ossobject objectForKey:@"AccessKeyId"];
            token.tSecretKey = [ossobject objectForKey:@"AccessKeySecret"];
            token.tToken = [ossobject objectForKey:@"SecurityToken"];
            token.expirationTimeInGMTFormat = [ossobject objectForKey:@"Expiration"];
            
            return token;
        }
    }];
    oss = [[OSSClient alloc] initWithEndpoint:endpoint credentialProvider:credential1];
    NSDictionary *m1 = @{
                         @"result": @"success",
                         @"id":_id
                         };
    [channel invokeMethod:@"onInit" arguments:m1];
}
- (void)update:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString * _id = call.arguments[@"id"];
    NSString * key = call.arguments[@"key"];
    if (oss == nil) {
        NSDictionary *m1 = @{
                             @"result":  @"fail",
                             @"id": _id,
                             @"key":key,
                             @"message":@"请先初始化"
                             };
        [channel invokeMethod:@"onUpload" arguments:m1];
    } else {
        NSString *bucket = call.arguments[@"bucket"];
        NSString * file = call.arguments[@"file"];
        OSSPutObjectRequest * put = [OSSPutObjectRequest new];
        // 必填字段
        put.bucketName = bucket;
        put.objectKey = key;
        put.uploadingFileURL = [NSURL fileURLWithPath:file];
        // put.uploadingData = <NSData *>; // 直接上传NSData
        put.uploadProgress = ^(int64_t bytesSent, int64_t totalByteSent, int64_t totalBytesExpectedToSend) {
            // 当前上传段长度、当前已经上传总长度、一共需要上传的总长度
            NSDictionary *m1 = @{
                                 @"key":key,
                                 @"currentSize":  [NSString stringWithFormat:@"%lld",totalByteSent],
                                 @"totalSize": [NSString stringWithFormat:@"%lld",totalBytesExpectedToSend],
                                 @"id":_id
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
                NSDictionary *m1 = @{
                                     @"result": @"success",
                                     @"key":key,
                                     @"id":_id
                                     };
                [channel invokeMethod:@"onUpload" arguments:m1];
            } else {
                
                NSDictionary *m1 = @{
                                     @"result": @"fail",
                                     @"key":key,
                                     @"id":_id,
                                     @"message":task.error
                                     };
                [channel invokeMethod:@"onUpload" arguments:m1];
            }
            return nil;
        }];
        // [putTask waitUntilFinished];
        // [put cancel];
    }
}
- (void)download:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString * _id = call.arguments[@"id"];
    NSString * key = call.arguments[@"key"];
    if (oss == nil) {
        NSDictionary *m1 = @{
                             @"result":  @"fail",
                             @"id": _id,
                             @"key":key,
                             @"message":@"请先初始化"
                             };
        [channel invokeMethod:@"onDownload" arguments:m1];
    } else {
        NSString * bucket = call.arguments[@"bucket"];
        NSString * process = call.arguments[@"process"];
        NSString * path = call.arguments[@"path"];
        
        OSSGetObjectRequest * request = [OSSGetObjectRequest new];
        
        // 必填字段
        request.bucketName = bucket;
        request.objectKey = key;
        
        // 可选字段
        request.downloadProgress = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
            NSDictionary *m1 = @{
                                 @"key":key,
                                 @"currentSize":  [NSString stringWithFormat:@"%lld",totalBytesWritten],
                                 @"totalSize": [NSString stringWithFormat:@"%lld",totalBytesExpectedToWrite],
                                 @"id":_id
                                 };
            [channel invokeMethod:@"onProgress" arguments:m1];
        };
        // request.range = [[OSSRange alloc] initWithStart:0 withEnd:99]; // bytes=0-99，指定范围下载
        request.downloadToFileURL = [NSURL fileURLWithPath:path]; // 如果需要直接下载到文件，需要指明目标文件地址
        if(![process isEqualToString:@""]){
            request.xOssProcess=process;
        }
        OSSTask * getTask = [oss getObject:request];
        [getTask continueWithBlock:^id(OSSTask *task) {
            if (!task.error) {
                NSDictionary *m1 = @{
                                     @"result": @"success",
                                     @"path":path,
                                     @"key":key,
                                     @"id":_id
                                     };
                [channel invokeMethod:@"onDownload" arguments:m1];
                
            } else {
                NSDictionary *m1 = @{
                                     @"result": @"fail",
                                     @"path":path,
                                     @"key":key,
                                     @"message":task.error,
                                     @"id":_id
                                     };
                [channel invokeMethod:@"onDownload" arguments:m1];
            }
            return nil;
        }];
    }
}
- (void)signUrl:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString * _id = call.arguments[@"id"];
    NSString * key = call.arguments[@"key"];
    if (oss == nil) {
        NSDictionary *m1 = @{
                             @"result":  @"fail",
                             @"id": _id,
                             @"key":key,
                             @"message":@"请先初始化"
                             };
        [channel invokeMethod:@"onSign" arguments:m1];
    } else {
        NSString * bucket = call.arguments[@"bucket"];
        NSString * type = call.arguments[@"type"];
        float interval = [call.arguments[@"interval"] floatValue];
        if ([type isEqualToString:@"0"]) {
            OSSTask *task = [oss presignPublicURLWithBucketName:bucket
                                                  withObjectKey:key];
            NSDictionary *m1 =nil;
            if (!task.error) {
                m1= @{
                      @"result":  @"success",
                      @"id": _id,
                      @"key":key,
                      @"url":task.result,
                      };
            } else {
                m1 = @{
                       @"result":  @"fail",
                       @"id": _id,
                       @"key":key,
                       @"url":@"",
                       };
            }
            [channel invokeMethod:@"onSign" arguments:m1];
        } else if ([type isEqualToString:@"1"]) {
            OSSTask * task =  nil;
            NSString * process = call.arguments[@"process"];
            if([process isEqualToString:@""]){
                task =  [oss presignConstrainURLWithBucketName:bucket withObjectKey:key withExpirationInterval:interval];
            }else{
                task =  [oss presignConstrainURLWithBucketName:bucket withObjectKey:key withExpirationInterval:interval withParameters:@{
                                                                                                                                         @"process":process
                                                                                                                                         }];
            }
            NSDictionary *m1 =nil;
            if (!task.error) {
                m1= @{
                      @"result":  @"success",
                      @"id": _id,
                      @"key":key,
                      @"url":task.result,
                      };
            } else {
                m1 = @{
                       @"result":  @"fail",
                       @"id": _id,
                       @"key":key,
                       @"url":@"",
                       };
            }
            
            [channel invokeMethod:@"onSign" arguments:m1];
        }else{
            
            NSDictionary *m1 = @{
                                 @"result":  @"fail",
                                 @"id": _id,
                                 @"key":key,
                                 @"message":@"签名类型错误"
                                 };
            [channel invokeMethod:@"onSign" arguments:m1];
        }
        
    }
}
- (void)des:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString * _key = call.arguments[@"key"];
    NSString * _type = call.arguments[@"type"];
    NSString * _data = call.arguments[@"data"];
    JKEncrypt * en = [[JKEncrypt alloc]init];
    NSString *_res=@"";
    if([_type isEqualToString:@"encrypt"]){
        _res= [en doEncryptStr:_data key:_key];
    }else if([_type isEqualToString:@"decrypt"]){
        _res=[en doDecEncryptStr:_data key:_key];
    }
    result(_res);
}
- (void)delete:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString * _id = call.arguments[@"id"];
    NSString * key = call.arguments[@"key"];
    if (oss == nil) {
        NSDictionary *m1 = @{
                             @"result":  @"fail",
                             @"id": _id,
                             @"key":key,
                             @"message":@"请先初始化"
                             };
        [channel invokeMethod:@"onDelete" arguments:m1];
    } else {
        OSSDeleteObjectRequest * delete = [OSSDeleteObjectRequest new];
        delete.bucketName =call.arguments[@"bucket"];
        delete.objectKey = key;
        
        OSSTask * deleteTask = [oss deleteObject:delete];
        
        [deleteTask continueWithBlock:^id(OSSTask *task) {
            NSDictionary *m1 =nil;
            if (!task.error) {
                m1= @{
                      @"result":  @"success",
                      @"id": _id,
                      @"key":key,
                      };
            }else{
                m1 = @{
                       @"result":  @"fail",
                       @"id": _id,
                       @"key":key,
                       @"message":@""
                       };
            }
            [channel invokeMethod:@"onDelete" arguments:m1];
            return nil;
        }];
    }
}

- (void)doesObjectExist:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString * key = call.arguments[@"key"];
    NSString * bucket =call.arguments[@"bucket"];
    if (oss == nil) {
        result([FlutterError errorWithCode:@"err"
                                   message:@"请先初始化"
                                   details:nil]);
    } else {
        NSError * error = nil;
        BOOL isExist = [oss doesObjectExistInBucket:bucket objectKey:key error:&error];
        if (!error) {
            if(isExist) {
                result([NSNumber numberWithBool:true]);
            } else {
                result([NSNumber numberWithBool:false]);
            }
        } else {
            result([FlutterError errorWithCode:@"err"
                                       message:@"发生错误"
                                       details:nil]);
        }
    }
}
@end
