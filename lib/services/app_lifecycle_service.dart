import 'package:flutter/material.dart';
import '../providers/app_provider.dart';

class AppLifecycleService extends WidgetsBindingObserver {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  AppProvider? _appProvider;
  bool _isInitialized = false;
  bool _isPausedForFileOperation = false;

  void initialize(AppProvider appProvider) {
    _appProvider = appProvider;
    WidgetsBinding.instance.addObserver(this);

    // Kurze Verzögerung um sicherzustellen dass die App vollständig gestartet ist
    Future.delayed(const Duration(seconds: 2), () {
      _isInitialized = true;
      print('🔐 AppLifecycleService initialisiert');
    });
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  // Temporär pausieren für File-Operationen
  void pauseForFileOperation() {
    print('🔐 Lifecycle-Monitoring pausiert für File-Operation');
    _isPausedForFileOperation = true;
  }

  void resumeAfterFileOperation() {
    print('🔐 Lifecycle-Monitoring wieder aktiviert nach File-Operation');
    _isPausedForFileOperation = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!_isInitialized || _appProvider == null) return;

    print('🔐 Lifecycle-Änderung: $state (pausiert: $_isPausedForFileOperation)');

    // Wenn pausiert für File-Operation, ignoriere Lifecycle-Änderungen
    if (_isPausedForFileOperation) {
      print('🔐 Lifecycle-Änderung ignoriert - File-Operation läuft');
      return;
    }

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        // App geht in den Hintergrund - sofort ausloggen
        if (_appProvider!.isAuthenticated) {
          print('🔐 App geht in Hintergrund - logge aus');
          _appProvider!.logout();
        }
        break;
      case AppLifecycleState.resumed:
        print('🔐 App ist wieder im Vordergrund');
        break;
    }
  }
}