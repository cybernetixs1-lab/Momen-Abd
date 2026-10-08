import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'application/waitlist_controller.dart';
import 'data/shared_preferences_waitlist_repository.dart';
import 'presentation/waitlist_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final repository = SharedPreferencesWaitlistRepository(preferences);
  final controller = WaitlistController(repository);
  await controller.load();
  runApp(RestaurantWaitlistApp(controller: controller));
}

class RestaurantWaitlistApp extends StatelessWidget {
  const RestaurantWaitlistApp({super.key, required this.controller});
  final WaitlistController controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Restaurant Waitlist',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    ),
    home: WaitlistPage(controller: controller),
  );
}
