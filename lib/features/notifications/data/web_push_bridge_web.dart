@JS()
library;

import 'dart:js_interop';

@JS('eventCrewEnablePush')
external JSPromise<JSString?> _eventCrewEnablePush();

Future<String?> requestWebPushToken() async {
  final token = await _eventCrewEnablePush().toDart;
  return token?.toDart;
}
