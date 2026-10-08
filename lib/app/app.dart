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
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: WaitlistPage(controller: controller),
      );
}
