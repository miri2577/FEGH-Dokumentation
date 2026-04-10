import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/platform_utils.dart';
import '../services/demo_data_service.dart';
import '../services/totp_service.dart';
import 'mek_recovery_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _totpController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSettingPassword = false;
  bool _awaitingTotp = false;
  String? _totpError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _totpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
              Theme.of(context).colorScheme.secondary.withValues(alpha:0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Consumer<AppProvider>(
                builder: (context, appProvider, child) {
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // App Icon/Logo
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha:0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.accessibility_new,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // App Title
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Eingliederungshilfe',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Subtitle
                              Text(
                                PlatformUtils.isWeb
                                    ? 'Digitale Dokumentation im Browser'
                                    : 'Digitale Dokumentation und Terminverwaltung',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 48),
                              
                              // Authentication Status
                              if (appProvider.isAuthenticating)
                                Column(
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Authentifizierung läuft...',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                )
                              else if (_awaitingTotp)
                                // TOTP 2FA Verification
                                _buildTotpVerification(context, appProvider)
                              else if (appProvider.useAppPassword && !appProvider.isPasswordSet)
                                // Password Setup (Web or Desktop without device auth)
                                _buildPasswordSetup(context, appProvider)
                              else if (appProvider.useAppPassword)
                                // Password Login (Web or Desktop without device auth)
                                _buildPasswordLogin(context, appProvider)
                              else
                                // Biometric/Native Authentication
                                _buildNativeAuthentication(context, appProvider),
                              
                              const SizedBox(height: 32),
                              
                              // Additional Info
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.security,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Sicherheit',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ihre Daten werden lokal und verschlüsselt gespeichert. Die App benötigt eine Authentifizierung zum Schutz sensibler Informationen.',
                                      style: Theme.of(context).textTheme.bodySmall,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),

                              // Einrichtung wiederholen
                              if (appProvider.setupCompleted) ...[
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: () async {
                                    await appProvider.resetSetup();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Der Einrichtungs-Assistent wird nach der Anmeldung erneut angezeigt.'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.tune, size: 16),
                                  label: const Text('Einrichtung wiederholen'),
                                  style: TextButton.styleFrom(
                                    textStyle: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordSetup(BuildContext context, AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Erstmalige Einrichtung',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Erstellen Sie einen Benutzernamen und ein sicheres Passwort für Ihre Eingliederungshilfe-App',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        // Username Field
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Benutzername',
            hintText: 'Mindestens 3 Zeichen',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Password Field
        TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Neues Passwort',
            hintText: 'Mindestens 6 Zeichen',
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Confirm Password Field
        TextField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Passwort bestätigen',
            hintText: 'Passwort wiederholen',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Setup Button
        FilledButton.icon(
          onPressed: _setupPassword,
          icon: const Icon(Icons.security),
          label: const Text('Passwort einrichten'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Demo Button
        FilledButton.tonal(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                icon: const Icon(Icons.info_outline, size: 48, color: Colors.orange),
                title: const Text('Demo-Modus'),
                content: const Text(
                  'Sie betreten den Demo-Modus.\n\n'
                  'Bitte geben Sie keine echten personenbezogenen Daten ein. '
                  'Die Daten werden nur lokal im Browser gespeichert und '
                  'können jederzeit verloren gehen.\n\n'
                  'Diese App befindet sich in einer frühen Beta-Phase.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Abbrechen'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await appProvider.authenticate();
                      await DemoDataService.loadDemoData(appProvider);
                    },
                    child: const Text('Demo starten'),
                  ),
                ],
              ),
            );
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.preview),
              SizedBox(width: 8),
              Text('Demo-Modus starten (ohne Anmeldung)'),
            ],
          ),
        ),
        
        // Error Message
        if (appProvider.authenticationError != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    appProvider.authenticationError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: appProvider.clearAuthError,
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordLogin(BuildContext context, AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Anmelden',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Geben Sie Ihren Benutzernamen und Ihr Passwort ein, um fortzufahren',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        // Username Field
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Benutzername',
            hintText: 'Ihr Benutzername',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Password Field
        TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          autofocus: true,
          onSubmitted: (_) => _loginWithPassword(),
          decoration: InputDecoration(
            labelText: 'Passwort',
            hintText: 'Ihr Passwort eingeben',
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Login Button
        FilledButton.icon(
          onPressed: _loginWithPassword,
          icon: const Icon(Icons.login),
          label: const Text('Anmelden'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        // Passwort vergessen
        Align(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: () => _showPasswordForgottenDialog(context),
            child: const Text('Passwort vergessen?'),
          ),
        ),

        // Error Message
        if (appProvider.authenticationError != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    appProvider.authenticationError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: appProvider.clearAuthError,
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNativeAuthentication(BuildContext context, AppProvider appProvider) {
    return Column(
      children: [
        // Main Authentication Button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => appProvider.authenticate(),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: Icon(
              appProvider.canUseBiometry
                  ? _getBiometricIcon(appProvider.biometryTypeName)
                  : Icons.lock,
            ),
            label: Text(
              appProvider.canUseBiometry
                  ? 'Mit ${appProvider.biometryTypeName} entsperren'
                  : 'Mit Passcode entsperren',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        
        // Alternative authentication option
        if (appProvider.canUseBiometry) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => appProvider.authenticateWithPasscode(),
            icon: const Icon(Icons.lock),
            label: const Text('Alternativ mit Passcode entsperren'),
          ),
        ],
        
        // Error Message
        if (appProvider.authenticationError != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    appProvider.authenticationError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: appProvider.clearAuthError,
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _setupPassword() {
    final username = _usernameController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    
    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Bitte füllen Sie alle Felder aus');
      return;
    }
    
    if (username.length < 3) {
      _showSnackBar('Benutzername muss mindestens 3 Zeichen lang sein');
      return;
    }
    
    if (password.length < 6) {
      _showSnackBar('Passwort muss mindestens 6 Zeichen lang sein');
      return;
    }
    
    if (password != confirmPassword) {
      _showSnackBar('Passwörter stimmen nicht überein');
      return;
    }
    
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.setCredentials(username, password).then((success) {
      if (success) {
        _showSnackBar('Anmeldedaten erfolgreich eingerichtet!');
        _usernameController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        // Automatisch einloggen
        appProvider.authenticateWithCredentials(username, password);
      }
    });
  }

  void _loginWithPassword() {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('Bitte geben Sie Benutzername und Passwort ein');
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.authenticateWithCredentials(username, password);

    // Nach erfolgreichem Login: TOTP-Schritt wenn aktiviert
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (appProvider.isAuthenticated && appProvider.hasTotpEnabled) {
        setState(() {
          _awaitingTotp = true;
          // Auth temporaer zuruecknehmen bis TOTP verifiziert
          appProvider.logout();
        });
      }
    });
  }

  void _verifyTotp() {
    final code = _totpController.text.trim();
    if (code.length != 6) {
      setState(() => _totpError = 'Bitte 6-stelligen Code eingeben');
      return;
    }
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (appProvider.verifyTotpCode(code)) {
      setState(() { _awaitingTotp = false; _totpError = null; });
      // Re-Authentifizieren
      final username = _usernameController.text;
      final password = _passwordController.text;
      appProvider.authenticateWithCredentials(username, password);
    } else {
      setState(() => _totpError = 'Ungültiger Code. Bitte erneut versuchen.');
      _totpController.clear();
    }
  }

  Widget _buildTotpVerification(BuildContext context, AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.security, size: 48, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Zwei-Faktor-Authentifizierung',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Geben Sie den 6-stelligen Code aus Ihrer Authenticator-App ein.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _totpController,
          decoration: InputDecoration(
            labelText: 'TOTP-Code',
            hintText: '000000',
            prefixIcon: const Icon(Icons.pin),
            errorText: _totpError,
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            letterSpacing: 8,
          ),
          onSubmitted: (_) => _verifyTotp(),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _verifyTotp,
          icon: const Icon(Icons.check),
          label: const Text('Verifizieren'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() { _awaitingTotp = false; _totpError = null; }),
          child: const Text('Zurueck zur Anmeldung'),
        ),
        const SizedBox(height: 16),
        // Verbleibende Zeit anzeigen
        StreamBuilder(
          stream: Stream.periodic(const Duration(seconds: 1)),
          builder: (context, _) {
            final remaining = TotpService.remainingSeconds();
            return Text(
              'Naechster Code in $remaining Sekunden',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            );
          },
        ),
      ],
    );
  }

  void _showPasswordForgottenDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.help_outline, size: 48, color: Colors.orange),
        title: const Text('Passwort vergessen'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Da FEGH-Dokumentation lokal auf Ihrem Gerät läuft, gibt es keinen automatischen E-Mail-Reset.',
            ),
            SizedBox(height: 12),
            Text(
              'Möglichkeiten:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Mitarbeiter: Wenden Sie sich an Ihre Teamleitung oder den Admin fuer einen Recovery-Token.'),
            SizedBox(height: 4),
            Text('• Admin: Nutzen Sie Ihren 12-Wort Recovery-Key (siehe Sicherheitsdokumente).'),
            SizedBox(height: 4),
            Text('• Wenn Sie sich mit Biometrie (Face ID / Touch ID) eingeloggt haben, nutzen Sie diese Option.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MekRecoveryScreen()),
              );
            },
            child: const Text('Recovery-Key verwenden'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  IconData _getBiometricIcon(String biometryTypeName) {
    switch (biometryTypeName) {
      case 'Face ID':
        return Icons.face;
      case 'Touch ID':
        return Icons.fingerprint;
      case 'Fingerprint':
        return Icons.fingerprint;
      default:
        return Icons.security;
    }
  }
}