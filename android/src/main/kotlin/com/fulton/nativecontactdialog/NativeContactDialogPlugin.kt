package com.fulton.nativecontactdialog

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import android.provider.ContactsContract
import android.provider.ContactsContract.CommonDataKinds
import android.provider.ContactsContract.CommonDataKinds.Organization
import android.provider.ContactsContract.CommonDataKinds.StructuredName
import android.content.*


class NativeContactDialogPlugin(private val context: Context): MethodCallHandler {
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "github.com.afulton11.plugins/native_contact_dialog")
      channel.setMethodCallHandler(NativeContactDialogPlugin(registrar.context()))
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "addContact" -> {
        val c = Contact.fromMap(call.arguments as HashMap<*, *>)
        if (this.addContact(c)) {
          result.success(null)
        } else {
          result.error(null, "Failed to add the contact", null)
        }
      }
      else -> result.notImplemented()
    }
  }

  private fun addContact(contact: Contact): Boolean {

    val intent = Intent(Intent.ACTION_INSERT_OR_EDIT).apply {
      // Sets the MIME type to match the Contacts Provider
      type = ContactsContract.Contacts.CONTENT_ITEM_TYPE

      var data = ArrayList<ContentValues>()

      val nameData = ContentValues().apply {
        put(ContactsContract.Data.MIMETYPE, StructuredName.CONTENT_ITEM_TYPE)
        put(StructuredName.GIVEN_NAME, contact.givenName)
        put(StructuredName.MIDDLE_NAME, contact.middleName)
        put(StructuredName.FAMILY_NAME, contact.familyName)
        put(StructuredName.PREFIX, contact.prefix)
        put(StructuredName.SUFFIX, contact.suffix)
      }
      data.add(nameData)

      val organizationData = ContentValues().apply {
        put(ContactsContract.Data.MIMETYPE, Organization.CONTENT_ITEM_TYPE)
        put(Organization.COMPANY, contact.company)
        put(Organization.TITLE, contact.jobTitle)
      }
      data.add(organizationData)

      //Phones
      for (phone in contact.phones) {
        val phoneData = ContentValues().apply {
          put(ContactsContract.Data.MIMETYPE, CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
          put(CommonDataKinds.Phone.NUMBER, phone.value)
          put(CommonDataKinds.Phone.TYPE, Item.stringToPhoneType(phone.label))
        }
        data.add(phoneData)
      }

      //Emails
      for (email in contact.emails) {
        val emailData = ContentValues().apply {
          put(ContactsContract.Data.MIMETYPE, CommonDataKinds.Email.CONTENT_ITEM_TYPE)
          put(CommonDataKinds.Email.ADDRESS, email.value)
          put(CommonDataKinds.Email.TYPE, Item.stringToEmailType(email.label))
        }
        data.add(emailData)
      }

      //Postal addresses
      for (address in contact.postalAddresses) {
        val postalData = ContentValues().apply {
          put(ContactsContract.Data.MIMETYPE, CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE)
          put(CommonDataKinds.StructuredPostal.TYPE, PostalAddress.stringToPostalAddressType(address.label))
          put(CommonDataKinds.StructuredPostal.STREET, address.street)
          put(CommonDataKinds.StructuredPostal.CITY, address.city)
          put(CommonDataKinds.StructuredPostal.REGION, address.region)
          put(CommonDataKinds.StructuredPostal.POSTCODE, address.postcode)
          put(CommonDataKinds.StructuredPostal.COUNTRY, address.country)
        }
        data.add(postalData)
      }

      putParcelableArrayListExtra(ContactsContract.Intents.Insert.DATA, data);
    }

    try {
      intent.putExtra(ContactsContract.Intents.Insert.NAME, contact.getDisplayName());
      context.startActivity(intent)
      return true
    } catch (e: Exception) {
      return false
    }

  }
}