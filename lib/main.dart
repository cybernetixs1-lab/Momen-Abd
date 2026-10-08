import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'features/waitlist/application/waitlist_controller.dart';
import 'features/waitlist/data/repositories/shared_preferences_waitlist_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final repository = SharedPreferencesWaitlistRepository(preferences);
  final controller = WaitlistController(repository);

  await controller.load();

  runApp(RestaurantWaitlistApp(controller: controller));
}
