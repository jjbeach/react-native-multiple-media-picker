#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(MultipleMediaPicker, NSObject)

RCT_EXTERN_METHOD(showMediaPicker:(NSArray *)selectedPhLocalIds
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject
)

@end
