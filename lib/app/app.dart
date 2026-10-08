import 'package:flutter/material.dart';

import '../features/waitlist/application/waitlist_controller.dart';
import '../features/waitlist/presentation/pages/waitlist_page.dart';

class RestaurantWaitlistApp extends StatelessWidget {
  const RestaurantWaitlistApp({super.key, required this.controller});

  final WaitlistController controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Restaurant Waitlist',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
          textTheme: const TextTheme(
            headlineSmall: TextStyle(fontWeight: FontWeight.w600),
            titleLarge: TextStyle(fontWeight: FontWeight.w600),
            titleMedium: TextStyle(fontWeight: FontWeight.w600),
          ),
          cardTheme: CardThemeData(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        home: WaitlistPage(controller: controller),
      );
}
