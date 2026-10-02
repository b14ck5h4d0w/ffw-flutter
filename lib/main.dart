import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app.dart';
import 'core/session.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();   // web: /league/bhai-brothers instead of /#/league/…
  Session.I.boot();
  runApp(const FfwApp());
}
