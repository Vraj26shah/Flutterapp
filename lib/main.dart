import 'package:flutter/material.dart';
import 'package:shopsphere/app/app.dart';
import 'package:shopsphere/core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const ShopSphereApp());
}
