import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../utils/responsive_utils.dart';
import '../providers/app_provider.dart';
import 'developer_warning_banner.dart';

class AdaptiveNavigation extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final Widget body;
  final FloatingActionButton? floatingActionButton;

  const AdaptiveNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.floatingActionButton,
  });

  @override
  State<AdaptiveNavigation> createState() => _AdaptiveNavigationState();
}

class _AdaptiveNavigationState extends State<AdaptiveNavigation> {
  bool _isFullScreen = false;

  bool get _isDesktopPlatform {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  Future<void> _toggleFullScreen() async {
    if (!_isDesktopPlatform) return;
    final isCurrentlyFullScreen = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!isCurrentlyFullScreen);
    setState(() {
      _isFullScreen = !isCurrentlyFullScreen;
    });
  }

  Widget _buildFullScreenButton() {
    if (!_isDesktopPlatform) return const SizedBox.shrink();
    return IconButton(
      icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
      tooltip: _isFullScreen ? 'Vollbild beenden' : 'Vollbild',
      onPressed: _toggleFullScreen,
    );
  }

  List<NavigationDestination> _buildDestinations(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final unreadCount = appProvider.unreadMessageCount;
    final isAdmin = appProvider.settings.isAdmin;

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Klienten',
      ),
      const NavigationDestination(
        icon: Icon(Icons.article_outlined),
        selectedIcon: Icon(Icons.article),
        label: 'Dokumentation',
      ),
      const NavigationDestination(
        icon: Icon(Icons.access_time_outlined),
        selectedIcon: Icon(Icons.access_time),
        label: 'Arbeitszeit',
      ),
      const NavigationDestination(
        icon: Icon(Icons.calendar_view_month_outlined),
        selectedIcon: Icon(Icons.calendar_view_month),
        label: 'Kalender',
      ),
      NavigationDestination(
        icon: Badge(
          backgroundColor: unreadCount > 0 ? Colors.red : Colors.transparent,
          textColor: Colors.white,
          label: unreadCount > 0 ? Text('$unreadCount') : null,
          child: const Icon(Icons.message_outlined),
        ),
        selectedIcon: Badge(
          backgroundColor: unreadCount > 0 ? Colors.red : Colors.transparent,
          textColor: Colors.white,
          label: unreadCount > 0 ? Text('$unreadCount') : null,
          child: const Icon(Icons.message),
        ),
        label: 'Nachrichten',
      ),
      const NavigationDestination(
        icon: Icon(Icons.assessment_outlined),
        selectedIcon: Icon(Icons.assessment),
        label: 'Berichte',
      ),
      const NavigationDestination(
        icon: Icon(Icons.file_download_outlined),
        selectedIcon: Icon(Icons.file_download),
        label: 'Export',
      ),
      const NavigationDestination(
        icon: Icon(Icons.help_outline),
        selectedIcon: Icon(Icons.help),
        label: 'Hilfe',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Einstellungen',
      ),
    ];

    if (isAdmin) {
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.admin_panel_settings_outlined),
        selectedIcon: Icon(Icons.admin_panel_settings),
        label: 'Verwaltung',
      ));
    }

    return destinations;
  }

  List<NavigationRailDestination> _buildRailDestinations(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final unreadCount = appProvider.unreadMessageCount;
    final isAdmin = appProvider.settings.isAdmin;

    final destinations = <NavigationRailDestination>[
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: Text('Klienten'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.article_outlined),
        selectedIcon: Icon(Icons.article),
        label: Text('Dokumentation'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.access_time_outlined),
        selectedIcon: Icon(Icons.access_time),
        label: Text('Arbeitszeit'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.calendar_view_month_outlined),
        selectedIcon: Icon(Icons.calendar_view_month),
        label: Text('Kalender'),
      ),
      NavigationRailDestination(
        icon: Badge(
          backgroundColor: unreadCount > 0 ? Colors.red : Colors.transparent,
          textColor: Colors.white,
          label: unreadCount > 0 ? Text('$unreadCount') : null,
          child: const Icon(Icons.message_outlined),
        ),
        selectedIcon: Badge(
          backgroundColor: unreadCount > 0 ? Colors.red : Colors.transparent,
          textColor: Colors.white,
          label: unreadCount > 0 ? Text('$unreadCount') : null,
          child: const Icon(Icons.message),
        ),
        label: const Text('Nachrichten'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.assessment_outlined),
        selectedIcon: Icon(Icons.assessment),
        label: Text('Berichte'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.file_download_outlined),
        selectedIcon: Icon(Icons.file_download),
        label: Text('Export'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.help_outline),
        selectedIcon: Icon(Icons.help),
        label: Text('Hilfe'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('Einstellungen'),
      ),
    ];

    if (isAdmin) {
      destinations.add(const NavigationRailDestination(
        icon: Icon(Icons.admin_panel_settings_outlined),
        selectedIcon: Icon(Icons.admin_panel_settings),
        label: Text('Verwaltung'),
      ));
    }

    return destinations;
  }

  @override
  Widget build(BuildContext context) {
    final navigationType = ResponsiveUtils.getNavigationType(context);

    switch (navigationType) {
      case NavigationType.rail:
        return _buildRailNavigation(context);
      case NavigationType.drawer:
        return _buildDrawerNavigation(context);
      case NavigationType.bottom:
        return _buildBottomNavigation(context);
    }
  }

  Widget _buildRailNavigation(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail
          Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: NavigationRail(
              selectedIndex: widget.selectedIndex,
              onDestinationSelected: widget.onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 1.0,
              leading: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: Icon(
                      Icons.accessibility_new,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildFullScreenButton(),
                  const SizedBox(height: 12),
                ],
              ),
              destinations: _buildRailDestinations(context),
            ),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                const DeveloperWarningBanner(),
                Expanded(
                  child: ResponsiveUtils.adaptiveScaffoldBody(
                    context: context,
                    body: widget.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: ResponsiveUtils.getFABLocation(context),
    );
  }

  Widget _buildDrawerNavigation(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FEGH-Dokumentation'),
        centerTitle: true,
        actions: [_buildFullScreenButton()],
      ),
      drawer: NavigationDrawer(
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: (index) {
          Navigator.pop(context); // Drawer schliessen
          widget.onDestinationSelected(index);
        },
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    Icons.accessibility_new,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'FEGH-Dokumentation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          ..._buildDestinations(context).map((destination) {
            final index = _buildDestinations(context).indexOf(destination);
            return NavigationDrawerDestination(
              icon: destination.icon,
              selectedIcon: destination.selectedIcon,
              label: Text(destination.label),
            );
          }),
        ],
      ),
      body: ResponsiveUtils.adaptiveScaffoldBody(
        context: context,
        body: widget.body,
      ),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: ResponsiveUtils.getFABLocation(context),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    // For mobile, show 4 main tabs + "Mehr" tab
    final mobileDestinations = [
      _AdaptiveNavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: 'Home',
      ),
      _AdaptiveNavigationDestination(
        icon: const Icon(Icons.people_outline),
        selectedIcon: const Icon(Icons.people),
        label: 'Klienten',
      ),
      _AdaptiveNavigationDestination(
        icon: const Icon(Icons.article_outlined),
        selectedIcon: const Icon(Icons.article),
        label: 'Doku',
      ),
      _AdaptiveNavigationDestination(
        icon: const Icon(Icons.calendar_view_month_outlined),
        selectedIcon: const Icon(Icons.calendar_view_month),
        label: 'Kalender',
      ),
      _AdaptiveNavigationDestination(
        icon: const Icon(Icons.more_horiz),
        selectedIcon: const Icon(Icons.more_horiz),
        label: 'Mehr',
      ),
    ];
    
    // Map selected index for mobile navigation
    int mobileSelectedIndex = 0;
    if (widget.selectedIndex == 0) {
      mobileSelectedIndex = 0; // Dashboard
    } else if (widget.selectedIndex == 1) {
      mobileSelectedIndex = 1; // Klienten
    } else if (widget.selectedIndex == 2) {
      mobileSelectedIndex = 2; // Dokumentation
    } else if (widget.selectedIndex == 4) {
      mobileSelectedIndex = 3; // Kalender
    } else {
      mobileSelectedIndex = 4; // Mehr (für Arbeitszeit, Export, Einstellungen)
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('FEGH-Dokumentation'),
        centerTitle: true,
        actions: [_buildFullScreenButton()],
      ),
      body: widget.selectedIndex == 999 // Special index for "Mehr" menu
          ? _buildMoreMenu(context)
          : ResponsiveUtils.adaptiveScaffoldBody(
              context: context,
              body: widget.body,
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: mobileSelectedIndex,
        onDestinationSelected: (index) {
          if (index == 4) {
            // Show "Mehr" menu
            widget.onDestinationSelected(999); // Special index for more menu
          } else {
            // Map mobile navigation back to full navigation
            switch (index) {
              case 0: widget.onDestinationSelected(0); break; // Dashboard
              case 1: widget.onDestinationSelected(1); break; // Klienten
              case 2: widget.onDestinationSelected(2); break; // Dokumentation
              case 3: widget.onDestinationSelected(4); break; // Kalender
            }
          }
        },
        destinations: mobileDestinations.map((dest) => NavigationDestination(
          icon: dest.icon,
          selectedIcon: dest.selectedIcon,
          label: dest.label,
        )).toList(),
      ),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: ResponsiveUtils.getFABLocation(context),
    );
  }

  Widget _buildMoreMenu(BuildContext context) {
    final moreOptions = <_MoreOption>[
      _MoreOption(
        icon: Icons.access_time,
        title: 'Arbeitszeit',
        subtitle: 'Arbeitsstunden verwalten',
        onTap: () => widget.onDestinationSelected(3),
      ),
      _MoreOption(
        icon: Icons.message,
        title: 'Nachrichten',
        subtitle: 'Nachrichten verwalten',
        onTap: () => widget.onDestinationSelected(5),
      ),
      _MoreOption(
        icon: Icons.assessment,
        title: 'Berichte',
        subtitle: 'Berichte erstellen und verwalten',
        onTap: () => widget.onDestinationSelected(6),
      ),
      _MoreOption(
        icon: Icons.file_download,
        title: 'Export',
        subtitle: 'Daten exportieren',
        onTap: () => widget.onDestinationSelected(7),
      ),
      _MoreOption(
        icon: Icons.help,
        title: 'Hilfe',
        subtitle: 'Hilfe und Dokumentation',
        onTap: () => widget.onDestinationSelected(8),
      ),
      _MoreOption(
        icon: Icons.settings,
        title: 'Einstellungen',
        subtitle: 'App-Einstellungen verwalten',
        onTap: () => widget.onDestinationSelected(9),
      ),
    ];

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (appProvider.settings.isAdmin) {
      moreOptions.add(_MoreOption(
        icon: Icons.admin_panel_settings,
        title: 'Verwaltung',
        subtitle: 'Teams, Mitarbeiter und Organisation verwalten',
        onTap: () => widget.onDestinationSelected(10),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mehr'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.onDestinationSelected(0), // Go back to Dashboard
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: moreOptions.length,
        itemBuilder: (context, index) {
          final option = moreOptions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  option.icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                option.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(option.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: option.onTap,
            ),
          );
        },
      ),
    );
  }
}

// Helper Widget für Drawer Header
class DrawerHeader extends StatelessWidget {
  const DrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
            ),
            child: Icon(
              Icons.accessibility_new,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'FEGH-Dokumentation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Digitale Dokumentation',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper classes for mobile navigation
class _AdaptiveNavigationDestination {
  final Widget icon;
  final Widget selectedIcon;
  final String label;

  const _AdaptiveNavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _MoreOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoreOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}