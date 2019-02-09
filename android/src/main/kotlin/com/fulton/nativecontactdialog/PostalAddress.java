package com.fulton.nativecontactdialog;

import android.annotation.TargetApi;
import android.database.Cursor;
import android.os.Build;
import android.provider.ContactsContract.CommonDataKinds.*;

import java.util.HashMap;

@TargetApi(Build.VERSION_CODES.ECLAIR)
public class PostalAddress {

    HashMap<String,String> map = new HashMap<>();

    PostalAddress(Cursor cursor){
        map.put("label", getLabel(cursor));
        map.put("street", cursor.getString(cursor.getColumnIndex(StructuredPostal.STREET)));
        map.put("city", cursor.getString(cursor.getColumnIndex(StructuredPostal.CITY)));
        map.put("postcode", cursor.getString(cursor.getColumnIndex(StructuredPostal.POSTCODE)));
        map.put("region", cursor.getString(cursor.getColumnIndex(StructuredPostal.REGION)));
        map.put("country", cursor.getString(cursor.getColumnIndex(StructuredPostal.COUNTRY)));
    }

    private PostalAddress(){}

    String label = map.get("label");
    String street = map.get("street");
    String city = map.get("city");
    String postcode = map.get("postcode");
    String region = map.get("region");
    String country = map.get("country");

    private String getLabel(Cursor cursor) {
        switch (cursor.getInt(cursor.getColumnIndex(StructuredPostal.TYPE))) {
            case StructuredPostal.TYPE_HOME:
                return "home";
            case StructuredPostal.TYPE_WORK:
                return "work";
            case StructuredPostal.TYPE_CUSTOM:
                final String label = cursor.getString(cursor.getColumnIndex(StructuredPostal.LABEL));
                return label != null ? label : "";
        }
        return "other";
    }

    public static PostalAddress fromMap(HashMap<String,String> postalAddress) {
        PostalAddress address = new PostalAddress();
        address.map = postalAddress;
        return address;
    }

    public static int stringToPostalAddressType(String label) {
        if(label != null) {
            switch (label) {
                case "home": return StructuredPostal.TYPE_HOME;
                case "work": return StructuredPostal.TYPE_WORK;
                default: return StructuredPostal.TYPE_OTHER;
            }
        }
        return StructuredPostal.TYPE_OTHER;
    }
}