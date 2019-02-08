package com.example.contactsuiservice

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import android.provider.ContactsContract
import android.provider.ContactsContract.CommonDataKinds
import android.provider.ContactsContract.CommonDataKinds.Organization
import android.provider.ContactsContract.CommonDataKinds.StructuredName
import android.provider.ContactsContract.CommonDataKinds.StructuredPostal
import android.text.TextUtils
import android.provider.ContactsContract.CommonDataKinds.Email
import android.provider.ContactsContract.CommonDataKinds.Phone
import android.os.Build
import android.annotation.TargetApi
import android.content.*
import android.os.AsyncTask
import android.database.Cursor
import android.net.Uri


class ContactsUiServicePlugin(private val context: Context): MethodCallHandler {
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "github.com.afulton11.plugins/contacts_view")
      channel.setMethodCallHandler(ContactsUiServicePlugin(registrar.context()))
    }
  }

  private val contentResolver = context.contentResolver;

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
      "getContacts" -> this.getContacts((call.argument<Any>("query") as String?)!!, call.argument<Any>("withThumbnails") as Boolean, result)
      "addContact" -> {
        val c = Contact.fromMap(call.arguments as HashMap<*, *>)
        if (this.addContact(c)) {
          result.success(null)
        } else {
          result.error(null, "Failed to add the contact", null)
        }
      }
      "deleteContact" -> {
        val ct = Contact.fromMap(call.arguments as HashMap<*, *>)
        if (this.deleteContact(ct)) {
          result.success(null)
        } else {
          result.error(null, "Failed to delete the contact, make sure it has a valid identifier", null)
        }
      }
      else -> result.notImplemented()
    }
  }

  private val PROJECTION = arrayOf(
          ContactsContract.Data.CONTACT_ID,
          ContactsContract.Profile.DISPLAY_NAME,
          ContactsContract.Contacts.Data.MIMETYPE,
          StructuredName.DISPLAY_NAME,
          StructuredName.GIVEN_NAME,
          StructuredName.MIDDLE_NAME,
          StructuredName.FAMILY_NAME,
          StructuredName.PREFIX,
          StructuredName.SUFFIX,
          Phone.NUMBER,
          Phone.TYPE,
          Phone.LABEL,
          Email.DATA,
          Email.ADDRESS,
          Email.TYPE,
          Email.LABEL,
          Organization.COMPANY,
          Organization.TITLE,
          StructuredPostal.FORMATTED_ADDRESS,
          StructuredPostal.TYPE,
          StructuredPostal.LABEL,
          StructuredPostal.STREET,
          StructuredPostal.POBOX,
          StructuredPostal.NEIGHBORHOOD,
          StructuredPostal.CITY,
          StructuredPostal.REGION,
          StructuredPostal.POSTCODE,
          StructuredPostal.COUNTRY)


  @TargetApi(Build.VERSION_CODES.ECLAIR)
  private fun getContacts(query: String, withThumbnails: Boolean, result: Result) {
    GetContactsTask(result, withThumbnails).execute(*arrayOf(query))
  }

  @TargetApi(Build.VERSION_CODES.CUPCAKE)
  private inner class GetContactsTask(
          private val getContactResult: Result,
          private val withThumbnails: Boolean)
      : AsyncTask<String, Void, ArrayList<HashMap<String, Any>>>() {

    @TargetApi(Build.VERSION_CODES.ECLAIR)
    override fun doInBackground(vararg query: String): ArrayList<HashMap<String, Any>> {
      val contacts = getContactsFrom(getCursor(query[0]))
      if (withThumbnails) {
        for (c in contacts) {
          setAvatarDataForContactIfAvailable(c)
        }
      }
      //Transform the list of contacts to a list of Map
      val contactMaps = ArrayList<HashMap<String, Any>>()
      for (c in contacts) {
        contactMaps.add(c.toMap())
      }

      return contactMaps
    }

    override fun onPostExecute(result: ArrayList<HashMap<String, Any>>) {
      getContactResult.success(result)
    }
  }

  private fun getCursor(query: String?): Cursor? {
    var selection = ContactsContract.Data.MIMETYPE + "=? OR " + ContactsContract.Data.MIMETYPE + "=? OR " + ContactsContract.Data.MIMETYPE + "=? OR " + ContactsContract.Data.MIMETYPE + "=? OR " + ContactsContract.Data.MIMETYPE + "=?"
    var selectionArgs = arrayOf(Email.CONTENT_ITEM_TYPE, Phone.CONTENT_ITEM_TYPE, StructuredName.CONTENT_ITEM_TYPE, Organization.CONTENT_ITEM_TYPE, StructuredPostal.CONTENT_ITEM_TYPE)
    if (query != null) {
      selectionArgs = arrayOf("%$query%")
      selection = ContactsContract.Contacts.DISPLAY_NAME_PRIMARY + " LIKE ?"
    }
    return contentResolver.query(ContactsContract.Data.CONTENT_URI, PROJECTION, selection, selectionArgs, null)
  }

  /**
   * Builds the list of contacts from the cursor
   * @param cursor
   * @return the list of contacts
   */
  private fun getContactsFrom(cursor: Cursor?): ArrayList<Contact> {
    val map = LinkedHashMap<String, Contact>()

    while (cursor != null && cursor.moveToNext()) {
      val columnIndex = cursor.getColumnIndex(ContactsContract.Data.CONTACT_ID)
      val contactId = cursor.getString(columnIndex)

      if (!map.containsKey(contactId)) {
        map[contactId] = Contact(contactId)
      }
      val contact = map[contactId];

      val mimeType = cursor.getString(cursor.getColumnIndex(ContactsContract.Data.MIMETYPE))
      contact!!.displayName = cursor.getString(cursor.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME))

      //NAMES
      if (mimeType == StructuredName.CONTENT_ITEM_TYPE) {
        contact.givenName = cursor.getString(cursor.getColumnIndex(StructuredName.GIVEN_NAME))
        contact.middleName = cursor.getString(cursor.getColumnIndex(StructuredName.MIDDLE_NAME))
        contact.familyName = cursor.getString(cursor.getColumnIndex(StructuredName.FAMILY_NAME))
        contact.prefix = cursor.getString(cursor.getColumnIndex(StructuredName.PREFIX))
        contact.suffix = cursor.getString(cursor.getColumnIndex(StructuredName.SUFFIX))
      } else if (mimeType == Phone.CONTENT_ITEM_TYPE) {
        val phoneNumber = cursor.getString(cursor.getColumnIndex(Phone.NUMBER))
        val type = cursor.getInt(cursor.getColumnIndex(Phone.TYPE))
        if (!TextUtils.isEmpty(phoneNumber)) {
          contact.phones.add(Item(Item.getPhoneLabel(type), phoneNumber))
        }
      } else if (mimeType == Email.CONTENT_ITEM_TYPE) {
        val email = cursor.getString(cursor.getColumnIndex(Email.ADDRESS))
        val type = cursor.getInt(cursor.getColumnIndex(Email.TYPE))
        if (!TextUtils.isEmpty(email)) {
          contact.emails.add(Item(Item.getEmailLabel(type, cursor), email))
        }
      } else if (mimeType == Organization.CONTENT_ITEM_TYPE) {
        contact.company = cursor.getString(cursor.getColumnIndex(Organization.COMPANY))
        contact.jobTitle = cursor.getString(cursor.getColumnIndex(Organization.TITLE))
      } else if (mimeType == StructuredPostal.CONTENT_ITEM_TYPE) {
        contact.postalAddresses.add(PostalAddress(cursor))
      }//ADDRESSES
      //ORG
      //MAILS
      //PHONES
    }
    return ArrayList(map.values)
  }

  private fun setAvatarDataForContactIfAvailable(contact: Contact) {
    val contactUri = ContentUris.withAppendedId(ContactsContract.Contacts.CONTENT_URI, Integer.parseInt(contact.identifier).toLong())
    val photoUri = Uri.withAppendedPath(contactUri, ContactsContract.Contacts.Photo.CONTENT_DIRECTORY)
    val avatarCursor = contentResolver.query(photoUri,
            arrayOf(ContactsContract.Contacts.Photo.PHOTO), null, null, null)
    if (avatarCursor != null && avatarCursor.moveToFirst()) {
      val avatar = avatarCursor.getBlob(0)
      contact.avatar = avatar
    }
    avatarCursor?.close()
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

  private fun deleteContact(contact: Contact): Boolean {
    val ops = ArrayList<ContentProviderOperation>()
    ops.add(ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
            .withSelection(ContactsContract.Data.CONTACT_ID + "=?", arrayOf(contact.identifier.toString()))
            .build())
    try {
      contentResolver.applyBatch(ContactsContract.AUTHORITY, ops)
      return true
    } catch (e: Exception) {
      return false
    }

  }
}