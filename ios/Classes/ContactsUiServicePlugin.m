#import "ContactsUiServicePlugin.h"
#import <contacts_ui_service/contacts_ui_service-Swift.h>

@implementation ContactsUiServicePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftContactsUiServicePlugin registerWithRegistrar:registrar];
}
  
@end
