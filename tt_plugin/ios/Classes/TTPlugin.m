#import "TTPlugin.h"
#import <tt_plugin/tt_plugin-Swift.h>

@implementation TTPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [TTOSVersionRequestHandler registerWithRegistrar:registrar];
    [TTInterfaceOrientationRequestHandler registerWithRegistrar:registrar];
    [TTTwitterRequestHandler registerWithRegistrar:registrar];
}

@end
