//
//  ContactsViewPluginDelegate.swift
//  contacts_ui_service
//
//  Created by Andrew Fulton on 2/9/19.
//

import Foundation
import Contacts
import ContactsUI

@available(iOS 9, *)
class ContactViewDelegate : NSObject, CNContactViewControllerDelegate {
  
  public let contactViewController: CNContactViewController
  public var didFinish: (() -> Void)?;
  
  init(withResult result: FlutterResult, withNewContact contact: CNContact) {
    self.contactViewController = CNContactViewController(forNewContact: contact)

    super.init();
    
    self.contactViewController.contactStore = CNContactStore()
    self.contactViewController.delegate = self
    self.contactViewController.allowsEditing = true
    result(nil);
  }
  
  func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
    viewController.dismiss(animated: true, completion: nil)
    self.didFinish?();
  }
  
  func close() {
    self.contactViewController(self.contactViewController, didCompleteWith: nil)
  }
}
