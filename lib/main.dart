import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/privacy_consent_screen.dart';
import 'screens/setup_wizard_screen.dart';
import 'utils/theme_config.dart';
import 'services/security_service.dart';
import 'services/app_lifecycle_service.dart';
import 'config/developer_mode.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Window Manager initialisieren (nur Desktop)
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      minimumSize: Size(800, 600),
      title: 'FEGH-Dokumentation',
    );
    await windowManager.waitUntilReadyToShow(windowOptions);
    await windowManager.show();
  }

  // Debug-Logs für Entwicklermodus
  print('🛠️ MAIN: App startet...');
  print('🛠️ MAIN: DeveloperMode.isActive = ${DeveloperMode.isActive}');
  print('🛠️ MAIN: DeveloperMode.isDeveloperMode = ${DeveloperMode.isDeveloperMode}');
  print('🛠️ MAIN: DeveloperMode.useKeychain = ${DeveloperMode.useKeychain}');
  print('🛠️ MAIN: DeveloperMode.showDeveloperWarnings = ${DeveloperMode.showDeveloperWarnings}');

  // Orientierung basierend auf Gerätetyp setzen
  await _setOrientationBasedOnDevice();

  SecurityService.enableScreenSecurity();

  // Security-Check nur auf nativen Plattformen (Web hat keine relevanten Checks)
  final SecurityStatus securityStatus;
  if (kIsWeb) {
    securityStatus = SecurityStatus(); // low risk default
  } else {
    securityStatus = await SecurityService.performSecurityCheck();
    if (securityStatus.riskLevel == SecurityRiskLevel.high) {
      print('🔒 Hohes Sicherheitsrisiko erkannt - App wird im Read-Only Modus gestartet');
    }
  }

  runApp(EingliederungshilfeApp(securityStatus: securityStatus));
}

class EingliederungshilfeApp extends StatefulWidget {
  final SecurityStatus securityStatus;

  const EingliederungshilfeApp({
    super.key,
    required this.securityStatus,
  });

  @override
  State<EingliederungshilfeApp> createState() => _EingliederungshilfeAppState();
}

class _EingliederungshilfeAppState extends State<EingliederungshilfeApp> {
  bool? _privacyConsented;

  @override
  void initState() {
    super.initState();
    _checkPrivacyConsent();
  }

  Future<void> _checkPrivacyConsent() async {
    final consented = await PrivacyConsentScreen.hasConsented();
    if (mounted) setState(() => _privacyConsented = consented);
  }

  @override
  void dispose() {
    AppLifecycleService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final appProvider = AppProvider()..initialize();
        AppLifecycleService().initialize(appProvider);
        return appProvider;
      },
      child: DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          return Consumer<AppProvider>(
            builder: (context, appProviderForTheme, child) {
              final ui = appProviderForTheme.settings.uiCustomization;
              final themeMode = appProviderForTheme.settings.darkModeEnabled
                  ? ThemeMode.dark
                  : ThemeMode.light;

              return MaterialApp(
            title: 'FEGH-Dokumentation',
            debugShowCheckedModeBanner: false,

            // Lokalisierung für deutsche Datums- und Zeitangaben
            locale: const Locale('de', 'DE'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('de', 'DE'),
              Locale('en', 'US'),
            ],

            // Dynamische Themes mit UI-Anpassungen
            theme: ThemeConfig.createLightTheme(dynamicColorScheme: lightDynamic, ui: ui),
            darkTheme: ThemeConfig.createDarkTheme(dynamicColorScheme: darkDynamic, ui: ui),
            themeMode: themeMode,

            navigatorKey: NavigationService.navigatorKey,
            
            // Responsive Framework für alle Bildschirmgrößen
            builder: (context, child) {
              return ResponsiveBreakpoints.builder(
                child: child!,
                breakpoints: [
                  const Breakpoint(start: 0, end: 450, name: MOBILE),
                  const Breakpoint(start: 451, end: 800, name: TABLET),
                  const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                  const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
                ],
              );
            },
            
            home: Consumer<AppProvider>(
              builder: (context, appProvider, child) {
            // Sicherheitswarnung anzeigen wenn nötig (aber nicht im Entwicklermodus)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!widget.securityStatus.isSecure &&
                  !DeveloperMode.isActive &&
                  ModalRoute.of(context)?.isCurrent == true) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => SecurityService.buildSecurityWarningDialog(widget.securityStatus),
                );
              }
            });

            if (appProvider.isLoading) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'FEGH-Dokumentation wird geladen...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (appProvider.error != null) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Fehler beim Laden',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          appProvider.error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => appProvider.initialize(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Erneut versuchen'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Datenschutzerklaerung muss VOR der Nutzung akzeptiert werden (Art. 13/14 DSGVO)
            if (_privacyConsented == false) {
              return PrivacyConsentScreen(
                onAccepted: () => setState(() => _privacyConsented = true),
              );
            }

            if (!appProvider.isAuthenticated) {
              return const AuthScreen();
            }

            if (!appProvider.setupCompleted) {
              return const SetupWizardScreen();
            }

                if (kIsWeb) {
                  // Web-Version: Warnung dass Daten nicht sicher gespeichert werden
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (ModalRoute.of(context)?.isCurrent == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Web-Version: Daten werden im Browser gespeichert und sind weniger geschuetzt als auf Desktop/Mobil.'),
                          duration: Duration(seconds: 8),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  });
                }
                return const HomeScreen();
              },
            ),
          );
            },
          );
        },
      ),
    );
  }
}

Future<void> _setOrientationBasedOnDevice() async {
  // Bildschirmgröße ermitteln
  final size = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;
  final devicePixelRatio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
  final screenWidth = size.width / devicePixelRatio;
  final screenHeight = size.height / devicePixelRatio;
  final diagonal = sqrt(screenWidth * screenWidth + screenHeight * screenHeight);

  // Tablet-Erkennung: Diagonale > 1000 Punkte (etwa 7+ Zoll)
  final isTablet = diagonal > 1000;

  if (isTablet) {
    // Tablet (iPad/Android Tablet): Alle Orientierungen erlauben
    print('🔄 Tablet erkannt - alle Orientierungen erlaubt');
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  } else {
    // Telefon (iPhone/Android Phone): Nur Hochformat erzwingen
    print('🔄 Telefon erkannt - erzwinge Hochformat');
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }
}
