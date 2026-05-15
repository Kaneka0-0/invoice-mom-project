// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

void registerNavigateCallback(void Function(String) fn) {
  js.context['_panhaNavigate'] = fn;
}
