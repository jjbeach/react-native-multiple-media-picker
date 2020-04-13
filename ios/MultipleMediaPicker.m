#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(MultipleMediaPicker, NSObject)

RCT_EXTERN_METHOD(showMediaPicker:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject
)

@end
