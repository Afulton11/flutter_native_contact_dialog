import Flutter
import UIKit
import Contacts
import ContactsUI


@available(iOS 9, *)
public class SwiftContactsUiServicePlugin: NSObject, FlutterPlugin {
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "github.com.afulton11.plugins/contacts_view", binaryMessenger: registrar.messenger())
    let instance = SwiftContactsUiServicePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    
    let viewFactory = FlutterNativeContactFactory(withMessenger: registrar.messenger());
    registrar.register(viewFactory, withId: "github.com.afulton11.views/contacts_view");
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if #available(iOS 10, *) {
      switch (call.method) {
      case "addContact":
        let args = call.arguments as! [String : Any];
        let contact = dictionaryToContact(dictionary: args["contact"] as! [String : Any]);
        requestAccess(completionHandler: { isAccessGranted in
          if (isAccessGranted) {
            let addResult = self.addContact(contact: contact);
            if (addResult == "") {
              result(nil)
            } else {
              result(FlutterError(code: "", message: addResult, details: nil));
            }
          }
        })
      case "getPlatformVersion":
        result("iOS " + UIDevice.current.systemVersion);
      default:
          result(FlutterMethodNotImplemented)
      }
    } else {
      result(FlutterError(code: "iOS 10.0 Required", message: "Contacts UI Service is only available in iOS 10.0 or newer.", details: nil)
      );
    }
  }
  
  @available(iOS 10, *)
  func addContact(contact: CNContact) -> String {
    return "";
  }
  
  @available(iOS 10, *)
  func requestAccess(completionHandler: @escaping (_ accessGranted: Bool) -> Void) {
    let store = CNContactStore();
    
    switch CNContactStore.authorizationStatus(for: .contacts) {
    case .authorized:
      completionHandler(true)
    case .denied:
      showSettingsAlert(completionHandler)
    case .restricted, .notDetermined:
      store.requestAccess(for: .contacts) { granted, error in
        if granted {
          completionHandler(true)
        } else {
          DispatchQueue.main.async {
            self.showSettingsAlert(completionHandler)
          }
        }
      }
    }
  }
  
  @available(iOS 10, *)
  private func showSettingsAlert(_ completionHandler: @escaping (_ accessGranted: Bool) -> Void) {
    let alert = UIAlertController(title: nil, message: "This app requires access to Contacts to proceed. Would you like to open settings and grant permission to contacts?", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { action in
      completionHandler(false)
      UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!)
    })
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in
      completionHandler(false)
    })
  }
  
  @available(iOS 9, *)
  func dictionaryToContact(dictionary : [String:Any]) -> CNMutableContact{
    let contact = CNMutableContact()
  
    //Simple fields
    contact.givenName = dictionary["givenName"] as? String ?? ""
    contact.familyName = dictionary["familyName"] as? String ?? ""
    contact.middleName = dictionary["middleName"] as? String ?? ""
    contact.namePrefix = dictionary["prefix"] as? String ?? ""
    contact.nameSuffix = dictionary["suffix"] as? String ?? ""
    contact.organizationName = dictionary["company"] as? String ?? ""
    contact.jobTitle = dictionary["jobTitle"] as? String ?? ""
    if let avatarData = (dictionary["avatar"] as? FlutterStandardTypedData)?.data {
        contact.imageData = avatarData
    }
  
    //Phone numbers
    if let phoneNumbers = dictionary["phones"] as? [[String:String]]{
      for phone in phoneNumbers where phone["value"] != nil {
        contact.phoneNumbers.append(CNLabeledValue(label:getPhoneLabel(label:phone["label"]),value:CNPhoneNumber(stringValue:phone["value"]!)))
      }
    }
  
    //Emails
    if let emails = dictionary["emails"] as? [[String:String]]{
      for email in emails where nil != email["value"] {
        let emailLabel = email["label"] ?? ""
        contact.emailAddresses.append(CNLabeledValue(label:emailLabel, value:email["value"]! as NSString))
      }
    }
  
    //Postal addresses
    if let postalAddresses = dictionary["postalAddresses"] as? [[String:String]]{
      for postalAddress in postalAddresses {
        let newAddress = CNMutablePostalAddress()
        newAddress.street = postalAddress["street"] ?? ""
        newAddress.city = postalAddress["city"] ?? ""
        newAddress.postalCode = postalAddress["postcode"] ?? ""
        newAddress.country = postalAddress["country"] ?? ""
        newAddress.state = postalAddress["region"] ?? ""
        let label = postalAddress["label"] ?? ""
        contact.postalAddresses.append(CNLabeledValue(label:label, value:newAddress))
      }
    }
  
    return contact
  }

  @available(iOS 9, *)
  func contactToDictionary(contact: CNContact) -> [String:Any]{
    
    var result = [String:Any]()
  
    //Simple fields
    result["identifier"] = contact.identifier
    result["displayName"] = CNContactFormatter.string(from: contact, style: CNContactFormatterStyle.fullName)
    result["givenName"] = contact.givenName
    result["familyName"] = contact.familyName
    result["middleName"] = contact.middleName
    result["prefix"] = contact.namePrefix
    result["suffix"] = contact.nameSuffix
    result["company"] = contact.organizationName
    result["jobTitle"] = contact.jobTitle
    if contact.isKeyAvailable(CNContactThumbnailImageDataKey) {
      if let avatarData = contact.thumbnailImageData {
        result["avatar"] = FlutterStandardTypedData(bytes: avatarData)
      }
    }
  
    //Phone numbers
    var phoneNumbers = [[String:String]]()
    for phone in contact.phoneNumbers{
      var phoneDictionary = [String:String]()
      phoneDictionary["value"] = phone.value.stringValue
      phoneDictionary["label"] = "other"
      if let label = phone.label{
        phoneDictionary["label"] = CNLabeledValue<NSString>.localizedString(forLabel: label)
      }
      phoneNumbers.append(phoneDictionary)
    }
    result["phones"] = phoneNumbers
  
    //Emails
    var emailAddresses = [[String:String]]()
    for email in contact.emailAddresses{
      var emailDictionary = [String:String]()
      emailDictionary["value"] = String(email.value)
      emailDictionary["label"] = "other"
      if let label = email.label{
        emailDictionary["label"] = CNLabeledValue<NSString>.localizedString(forLabel: label)
      }
      emailAddresses.append(emailDictionary)
    }
    result["emails"] = emailAddresses
  
    //Postal addresses
    var postalAddresses = [[String:String]]()
    for address in contact.postalAddresses{
      var addressDictionary = [String:String]()
      addressDictionary["label"] = ""
      if let label = address.label{
        addressDictionary["label"] = CNLabeledValue<NSString>.localizedString(forLabel: label)
      }
      addressDictionary["street"] = address.value.street
      addressDictionary["city"] = address.value.city
      addressDictionary["postcode"] = address.value.postalCode
      addressDictionary["region"] = address.value.state
      addressDictionary["country"] = address.value.country
    
      postalAddresses.append(addressDictionary)
    }
    result["postalAddresses"] = postalAddresses
  
    return result
  }

  @available(iOS 9, *)
  func getPhoneLabel(label: String?) -> String{
    let labelValue = label ?? ""
    switch(labelValue){
    case "main": return CNLabelPhoneNumberMain
    case "mobile": return CNLabelPhoneNumberMobile
    case "iPhone": return CNLabelPhoneNumberiPhone
    default: return labelValue
    }
  }
}
