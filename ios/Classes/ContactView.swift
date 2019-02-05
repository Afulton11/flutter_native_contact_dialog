//
//  ContactView.swift
//  contacts_ui_service
//
//  Created by Andrew Fulton on 2/4/19.
//

import Foundation
import ContactsUI

enum ContactViewError : Error {
  case OutdatedPlatformVersion(minimumVersion: String);
}

@available(iOS 9, *)
class FlutterNativeContactFactory : NSObject, FlutterPlatformViewFactory {
  
  var _messenger: FlutterBinaryMessenger;
  
  init(withMessenger messenger: FlutterBinaryMessenger) {
    self._messenger = messenger;
  }
  
  public func createArgsCodec() -> FlutterMessageCodec {
    return FlutterStandardMessageCodec.sharedInstance();
  }
  
  public func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?) -> FlutterPlatformView {
    let contactController = FlutterNativeContactController(
      withFrame: frame,
      withIdentifier: viewId,
      withArguments: args,
      withMessenger: self._messenger
    );
    
    return contactController;
  }
}

@available(iOS 9, *)
class FlutterNativeContactController : NSObject, FlutterPlatformView {
  
  let contactController: CNContactViewController;
  let viewId: Int64;
  let methodChannel: FlutterMethodChannel;
  var contactView: UIView;
  
  
  init(withFrame frame: CGRect,
       withIdentifier viewId: Int64,
       withArguments args: Any?,
       withMessenger messenger: FlutterBinaryMessenger) {
    self.contactController = CNContactViewController(forNewContact: CNContact());
    self.contactController.allowsActions = true;
    self.contactController.allowsEditing = true;
    self.contactView = contactController.view;
    self.viewId = viewId;
    self.methodChannel = FlutterMethodChannel(
      name: "github.com.afulton11.views/contact_view_\(viewId)",
      binaryMessenger: messenger)
    
    super.init();
    
    weak var weakSelf = self;
    self.methodChannel.setMethodCallHandler({ (call: FlutterMethodCall, result: FlutterResult) in
      weakSelf?.onMethod(call: call, result: result)
    })
  }
  
  func view() -> UIView {
    contactView.layoutIfNeeded();
    return contactView;
  }
  
  func onMethod(call: FlutterMethodCall, result: FlutterResult) {
    contactController.perform(contactController.editButtonItem.action);
    result(FlutterMethodNotImplemented);
  }
}


@available(iOS 9, *)
class ContactView : NSObject, FlutterPlatformView {
  
  let viewController: ContactViewController?;
  
  init(for contact: CNContact) {
    self.viewController = ContactViewController(coder: NSCoder());
  }
  
  init(forNewContact contact: CNContact) {
    self.viewController = ContactViewController(coder: NSCoder());
  }
  
  func view() -> UIView {
      return self.viewController!.view
  }
}
