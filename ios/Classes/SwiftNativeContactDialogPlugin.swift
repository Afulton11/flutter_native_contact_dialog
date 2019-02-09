import Flutter
import UIKit
import Contacts

@available(iOS 9, *)
public class SwiftNativeContactDialogPlugin: NSObject, FlutterPlugin {
  
  private let delegate: IContactViewDelegate
  
  init(pluginRegistrar: FlutterPluginRegistrar, viewController: UIViewController, window: UIWindow) {
    self.delegate = ContactViewPluginDelegate(registrar: pluginRegistrar, rootViewController: viewController, window: window)
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "github.com.afulton11.plugins/native_contact_dialog", binaryMessenger: registrar.messenger())
    
    let window = (UIApplication.shared.delegate?.window!)!;
    let viewController: UIViewController = window.rootViewController!;
    
    let instance = SwiftNativeContactDialogPlugin(
      pluginRegistrar: registrar,
      viewController: viewController,
      window: window)

    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch (call.method) {
    case "addContact":
      let contact = dictionaryToContact(dictionary: call.arguments as! [String : Any]);
      self.delegate.beginAddContact(result: result, forNewContact: contact)
    default:
        result(FlutterMethodNotImplemented)
    }
  }
  
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
        contact.phoneNumbers.append(
          CNLabeledValue(
            label: getPhoneLabel(
              label: phone["label"]),
              value: CNPhoneNumber(stringValue: phone["value"]!)))
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
