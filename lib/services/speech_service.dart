// Speech service temporarily disabled for Android compatibility
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

// Temporary LocaleName stub
class LocaleName {
  final String localeId;
  final String name;

  LocaleName(this.localeId, this.name);
}

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  bool _isListening = false;
  bool _speechEnabled = false;
  String _recognizedText = "";
  String _lastError = "Speech service temporarily disabled";
  double _confidenceLevel = 0.0;

  bool get isListening => _isListening;
  bool get speechEnabled => _speechEnabled;
  String get recognizedText => _recognizedText;
  String get lastError => _lastError;
  double get confidenceLevel => _confidenceLevel;

  List<LocaleName> _locales = [LocaleName('de-DE', 'Deutsch')];
  LocaleName? _selectedLocale;

  List<LocaleName> get availableLocales => _locales;
  LocaleName? get selectedLocale => _selectedLocale;

  Future<bool> initializeSpeech() async {
    print('🎤 Speech service disabled for Android compatibility');
    _speechEnabled = false;
    return false;
  }

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status == PermissionStatus.granted;
  }

  Future<void> startListening({
    Function(String)? onResult,
    Function(String)? onPartialResult,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    print('🎤 ❌ Speech listening disabled');
    _lastError = "Speech service temporarily disabled";
  }

  Future<void> stopListening() async {
    _isListening = false;
  }

  Future<void> cancelListening() async {
    _isListening = false;
  }

  String appendToText(String existingText, String newText) {
    if (existingText.isEmpty) return newText;
    return '$existingText $newText';
  }

  void dispose() {
    // Nothing to dispose
  }

  void setLocale(LocaleName locale) {
    _selectedLocale = locale;
  }
}