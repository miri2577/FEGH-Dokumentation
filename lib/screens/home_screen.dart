import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/app_provider.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/traffic_light_dashboard_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/recent_appointments_list.dart';
import '../widgets/adaptive_navigation.dart';
import '../widgets/developer_warning_banner.dart';
import '../utils/responsive_utils.dart';
import '../utils/theme_config.dart';
import 'clients_screen.dart';
import 'work_time_screen.dart';
import 'calendar_screen.dart';
import 'export_screen.dart';
import 'messages_screen.dart';
import 'create_appointment_screen.dart';
import 'settings_screen.dart';
import 'mitarbeiter_screen.dart';
import 'hilfe_screen.dart';
import 'berichte_screen.dart';
import 'benutzerprofil_screen.dart';
import 'create_client_screen.dart';
import 'dokumentation_uebersicht_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final Map<int, Widget> _screenCache = {};

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _getScreen(int index) {
    return _screenCache.putIfAbsent(index, () {
      switch (index) {
        case 0: return DashboardTab(onNavigateToTab: _navigateToTab);
        case 1: return const ClientsScreen();
        case 2: return const DokumentationUebersichtScreen();
        case 3: return const WorkTimeScreen();
        case 4: return const CalendarScreen();
        case 5: return const MessagesScreen();
        case 6: return const BerichteScreen();
        case 7: return const ExportScreen();
        case 8: return const HilfeScreen();
        case 9: return const SettingsScreen();
        case 10: return const AdminDashboardScreen();
        default: return Container();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigation(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      body: _getScreen(_currentIndex),
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 4)
          ? FloatingActionButton.extended(
              heroTag: "home_fab",
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateAppointmentScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: ResponsiveUtils.isDesktop(context)
                  ? const Text('Neuer Termin erstellen')
                  : const Text('Neuer Termin'),
            )
          : null,
    );
  }
}

class DashboardTab extends StatelessWidget {
  final Function(int)? onNavigateToTab;
  
  const DashboardTab({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    // Desktop-Layout hat keinen AppBar (Navigation Rail hat schon Branding)
    final showAppBar = !ResponsiveUtils.isDesktop(context);
    
    return Scaffold(
      appBar: showAppBar ? AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Consumer<AppProvider>(
            builder: (context, appProvider, child) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'logout':
                      _showLogoutDialog(context, appProvider);
                      break;
                    case 'refresh':
                      appProvider.refreshData();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: ListTile(
                      leading: Icon(Icons.refresh),
                      title: Text('Aktualisieren'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Abmelden'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ) : null,
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (appProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final isDataLoading = appProvider.isDataLoading;

          if (appProvider.error != null) {
            return Center(
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
                    'Fehler beim Laden der Daten',
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
                    onPressed: () => appProvider.refreshData(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => appProvider.refreshData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ResponsiveUtils.adaptiveScaffoldBody(
                context: context,
                body: Padding(
                  padding: ResponsiveUtils.getScreenPadding(context),
                  child: AnimationLimiter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: ResponsiveUtils.getAnimationDuration(context),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 30.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          // Dezenter Ladeindikator während Daten im Hintergrund laden
                          if (isDataLoading)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: LinearProgressIndicator(),
                            ),

                          // Welcome Section
                          _buildWelcomeSection(context, appProvider),
                          
                          SizedBox(height: ResponsiveUtils.getSpacing(context)),
                          
                          // Statistics Section - Responsive Grid
                          _buildStatisticsSection(context, appProvider),
                          
                          SizedBox(height: ResponsiveUtils.getSpacing(context)),
                          
                          // Desktop: Side-by-side layout für Actions und Recent
                          if (ResponsiveUtils.isDesktop(context))
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: _buildQuickActionsSection(context),
                                ),
                                SizedBox(width: ResponsiveUtils.getSpacing(context)),
                                Expanded(
                                  flex: 2,
                                  child: _buildRecentAppointmentsSection(context, appProvider),
                                ),
                              ],
                            )
                          else ...[
                            // Mobile/Tablet: Vertical layout
                            _buildQuickActionsSection(context),
                            SizedBox(height: ResponsiveUtils.getSpacing(context)),
                            _buildRecentAppointmentsSection(context, appProvider),
                          ],
                          
                          const SizedBox(height: 100), // Space for FAB
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, AppProvider appProvider) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Guten Morgen';
    } else if (hour < 18) {
      greeting = 'Guten Tag';
    } else {
      greeting = 'Guten Abend';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appProvider.currentUser != null
                        ? 'Willkommen, ${appProvider.currentUser!.vollstaendigerName}'
                        : appProvider.settings.userName.isEmpty
                            ? 'Willkommen bei FEGH-Dokumentation'
                            : 'Willkommen, ${appProvider.settings.userName}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.7),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BenutzerprofilScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context, AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Übersicht',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveUtils.getTitleFontSize(context),
          ),
        ),
        SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
        
        // Dashboard Cards - Row Layout wie im Arbeitszeit-Tab
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    title: 'Klienten',
                    value: '${appProvider.totalClients}',
                    icon: Icons.people,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DashboardCard(
                    title: 'Termine Gesamt',
                    value: '${appProvider.totalAppointments}',
                    icon: Icons.calendar_today,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    title: 'Diese Woche',
                    value: '${appProvider.thisWeekAppointments}',
                    icon: Icons.today,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DashboardCard(
                    title: 'Dokumentiert',
                    value: '${(appProvider.documentationRate * 100).toStringAsFixed(0)}%',
                    icon: Icons.description,
                    color: ThemeConfig.semanticColors['success']!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (appProvider.totalFahrwege > 0)
              Row(
                children: [
                  Expanded(
                    child: DashboardCard(
                      title: 'Fahrwege (Monat)',
                      value: '${appProvider.kmDrivenThisMonth.toStringAsFixed(1)} km',
                      icon: Icons.directions_car,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DashboardCard(
                      title: 'Fahrten',
                      value: '${appProvider.totalFahrwege}',
                      icon: Icons.route,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            if (appProvider.totalFahrwege > 0)
              const SizedBox(height: 16),
            TrafficLightDashboardCard(
              title: 'Stundenverbrauch',
              value: '${appProvider.averageHoursUsage.toStringAsFixed(0)}%',
              status: appProvider.hoursUsageStatus,
              redCount: appProvider.clientsInRedZone,
              yellowCount: appProvider.clientsInYellowZone,
              greenCount: appProvider.clientsInGreenZone,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schnellzugriff',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                title: 'Neuer Klient',
                icon: Icons.person_add,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CreateClientScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: QuickActionButton(
                title: 'Dokumentation',
                icon: Icons.article_outlined,
                onTap: () {
                  onNavigateToTab?.call(2);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                title: 'Termine',
                icon: Icons.calendar_view_day,
                onTap: () {
                  onNavigateToTab?.call(4);
                },
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentAppointmentsSection(BuildContext context, AppProvider appProvider) {
    final recentAppointments = appProvider.appointments.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aktuelle Termine',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                onNavigateToTab?.call(4);
              },
              child: const Text('Alle'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentAppointments.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Noch keine Termine vorhanden',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Erstellen Sie Ihren ersten Termin',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          RecentAppointmentsList(appointments: recentAppointments),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abmelden'),
        content: const Text(
          'Möchten Sie sich wirklich abmelden? Die App wird gesperrt und benötigt eine erneute Authentifizierung.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              appProvider.logout();
            },
            child: const Text('Abmelden'),
          ),
        ],
      ),
    );
  }
}