import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/chat_provider.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const SamagraAIApp());
}

class SamagraAIApp extends StatelessWidget {
  const SamagraAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChatProvider(),
      child: MaterialApp(
        title: 'SamagraAI',
        theme: AppTheme.lightTheme,
        home: const ChatScreen(),
        routes: {'/settings': (context) => const SettingsScreen()},
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
