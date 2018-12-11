#import <Flutter/Flutter.h>

@interface AliossflutterPlugin : NSObject<FlutterPlugin>;

- (void)init:(FlutterMethodCall *)call result:(FlutterResult)result;
- (void)update:(FlutterMethodCall *)call result:(FlutterResult)result;
- (void)download:(FlutterMethodCall *)call result:(FlutterResult)result;
- (void)signUrl:(FlutterMethodCall *)call result:(FlutterResult)result;
@end
