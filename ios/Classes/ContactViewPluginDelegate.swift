//
//  ContactsViewPluginDelegate.swift
//  contacts_ui_service
//
//  Created by Andrew Fulton on 2/9/19.
//

import Foundation
import Contacts
import ContactsUI

protocol IContactViewDelegate {
  @available(iOS 9, *)
  func beginAddContact(result: @escaping FlutterResult, forNewContact contact: CNContact);
}

@available(iOS 9, *)
class ContactViewPluginDelegate : NSObject, IContactViewDelegate, CNContactViewControllerDelegate {
  
  private let registrar: FlutterPluginRegistrar
  private let window: UIWindow
  private let flutterRootViewController: UIViewController
  private let navigationController: UINavigationController
  
  private var contactViewController: CNContactViewController?
  
  init(registrar: FlutterPluginRegistrar, rootViewController: UIViewController, window: UIWindow) {
    self.registrar = registrar
    self.window = window;
    self.flutterRootViewController = rootViewController
    
    self.navigationController = UINavigationController(rootViewController: self.flutterRootViewController)
    self.navigationController.setNavigationBarHidden(true, animated: true)
    self.window.rootViewController = self.navigationController
  }
  
  public func beginAddContact(result: @escaping FlutterResult, forNewContact contact: CNContact) {
    self.contactViewController = CNContactViewController(forNewContact: contact)
    self.contactViewController?.contactStore = CNContactStore()
    self.contactViewController?.delegate = self
    self.contactViewController?.allowsEditing = true
    
    DispatchQueue.main.async {
      self.navigationController.setNavigationBarHidden(false, animated: true)
      self.navigationController.pushViewController(self.contactViewController!, animated: true)
    }
  }
  
  func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
    DispatchQueue.main.async {
      self.navigationController.setNavigationBarHidden(true, animated: true)
      self.navigationController.popToViewController(self.flutterRootViewController, animated: true)
    }
  }
}
