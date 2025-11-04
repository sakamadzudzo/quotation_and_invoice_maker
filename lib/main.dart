import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/company_provider.dart';
import 'providers/client_provider.dart';
import 'providers/quotation_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'utils/themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize settings
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => QuotationProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Quotation & Invoice Maker',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: settings.themeMode,
          home: const MainNavigationScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
