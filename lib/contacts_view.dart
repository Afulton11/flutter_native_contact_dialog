import 'package:contacts_ui_service/contacts_ui_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

typedef void ContactsViewCreatedCallback(ContactsViewController controller);

class ContactsView extends StatefulWidget {

  ContactsView({
    Key key,
    this.onContactsViewCreated,
  }) : super(key: key);

  final ContactsViewCreatedCallback onContactsViewCreated;

  @override
  State<StatefulWidget> createState() {
    return _ContactsViewState();
  }

}

class _ContactsViewState extends State<ContactsView> {
  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _buildAndroidView();
      case TargetPlatform.iOS:
        return _buildIOSView();
      default:
        return Text("$defaultTargetPlatform is not supported by the contacts_view plugin.");
    }
  }

  Widget _buildAndroidView() {
    return AndroidView(
      viewType: 'github.com.afulton11.views/contacts_view',
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }

  Widget _buildIOSView() {
    return UiKitView(
      viewType: 'github.com.afulton11.views/contacts_view',
      onPlatformViewCreated: _onPlatformViewCreated,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                        Factory<OneSequenceGestureRecognizer>(
                          () => TapGestureRecognizer(),
                        ),
                      ].toSet(),
      creationParamsCodec: const StandardMessageCodec()
    );
  }

  void _onPlatformViewCreated(int id) {
    if (widget.onContactsViewCreated == null) {
      return;
    }
    widget.onContactsViewCreated(new ContactsViewController._(id));
  }
}

class ContactsViewController {
  ContactsViewController._(int id)
    : channel = MethodChannel('github.com.afulton11.views/contacts_view_$id');

  final MethodChannel channel;

  Future<void> setContact(Contact contact) async {
    return null;
  }
}