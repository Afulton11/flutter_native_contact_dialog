#import "NativeContactDialogPlugin.h"
#import <native_contact_dialog/native_contact_dialog-Swift.h>

@implementation NativeContactDialogPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftNativeContactDialogPlugin registerWithRegistrar:registrar];
}
  
@end
