import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../models/email_config.dart';
import '../providers/auth_provider.dart';
import '../providers/email_automation_provider.dart';
import '../services/window_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text(
              'Are you sure you want to sign out? This will close all automation windows.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );

    if (shouldLogout == true && mounted) {
      WindowManager.closeAllWindows(context);
      await authProvider.logout();
    }
  }

  Future<void> _createNewAutomation() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Create config with user's Gmail credentials pre-filled
    final config = EmailConfig(
      senderEmail: authProvider.userEmail ?? '',
      senderPassword: authProvider.userPassword ?? '',
    );

    await WindowManager.openAutomationWindow(context, config: config);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(MdiIcons.emailOutline, size: 28),
            const SizedBox(width: 12),
            const Text('Email Automation'),
          ],
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    authProvider.userEmail?.substring(0, 1).toUpperCase() ??
                        'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                onSelected: (value) async {
                  if (value == 'logout') {
                    await _handleLogout();
                  }
                },
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Signed in as:',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                            Text(
                              authProvider.userEmail ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(MdiIcons.logout, size: 20),
                            const SizedBox(width: 8),
                            const Text('Sign Out'),
                          ],
                        ),
                      ),
                    ],
              );
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(),
                const SizedBox(height: 32),
                _buildActiveAutomations(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      MdiIcons.home,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Welcome back!',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'You are signed in as ${authProvider.userEmail}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _createNewAutomation,
                        icon: Icon(MdiIcons.plus),
                        label: const Text('Create New Automation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveAutomations() {
    return ValueListenableBuilder<int>(
      valueListenable: WindowManager.windowsChangeNotifier,
      builder: (context, _, __) {
        final runningCount = WindowManager.openWindowsCount;
        final runningWindows = WindowManager.openWindows;
        final allWindowsCount = WindowManager.allOpenWindowsCount;
        final allWindows = WindowManager.allOpenWindows;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Windows',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$runningCount running, $allWindowsCount total',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (runningCount == 0 && allWindowsCount == 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        MdiIcons.windowOpen,
                        size: 32,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Active Windows',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create a new automation to get started.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _createNewAutomation,
                        icon: Icon(MdiIcons.plus),
                        label: const Text('Create New Automation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  if (runningCount > 0) ...[
                    Text(
                      'Running Automations',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...runningWindows.map(
                      (windowId) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Card(
                          child: ListTile(
                            leading: Icon(
                              MdiIcons.emailOutline,
                              color: Theme.of(context).primaryColor,
                            ),
                            title: Text('Automation Window #$windowId'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _getStatusColor(windowId),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getStatusText(windowId),
                                      style: TextStyle(
                                        color: _getStatusColor(windowId),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'To: ${WindowManager.getWindowConfig(windowId)?.recipientEmail ?? 'Not set'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Interval: ${WindowManager.getWindowConfig(windowId)?.intervalMinutes ?? 120} min',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed:
                                      () =>
                                          WindowManager.restoreWindowWithContext(
                                            windowId,
                                            context,
                                          ),
                                  tooltip: 'Show Window',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed:
                                      () => WindowManager.closeWindow(windowId),
                                  tooltip: 'Close Window',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (allWindowsCount > runningCount) ...[
                    Text(
                      'Open Windows (Not Running)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...allWindows
                        .where((windowId) => !runningWindows.contains(windowId))
                        .map(
                          (windowId) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Card(
                              child: ListTile(
                                leading: Icon(
                                  MdiIcons.emailOutline,
                                  color: Colors.grey.shade400,
                                ),
                                title: Text('Automation Window #$windowId'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Not Started',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      'To: ${WindowManager.getWindowConfig(windowId)?.recipientEmail ?? 'Not set'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.open_in_new),
                                      onPressed:
                                          () =>
                                              WindowManager.restoreWindowWithContext(
                                                windowId,
                                                context,
                                              ),
                                      tooltip: 'Show Window',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed:
                                          () => WindowManager.closeWindow(
                                            windowId,
                                          ),
                                      tooltip: 'Close Window',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    const SizedBox(height: 16),
                  ],
                  OutlinedButton.icon(
                    onPressed: _createNewAutomation,
                    icon: Icon(MdiIcons.plus),
                    label: const Text('Add New Automation'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(int windowId) {
    final status = WindowManager.getWindowStatus(windowId);
    switch (status) {
      case AutomationStatus.running:
        return const Color(0xFF10B981);
      case AutomationStatus.starting:
        return const Color(0xFFF59E0B);
      case AutomationStatus.stopping:
        return const Color(0xFFF59E0B);
      case AutomationStatus.error:
        return const Color(0xFFEF4444);
      case AutomationStatus.stopped:
        return Colors.grey;
    }
  }

  String _getStatusText(int windowId) {
    final status = WindowManager.getWindowStatus(windowId);
    switch (status) {
      case AutomationStatus.running:
        return 'Running';
      case AutomationStatus.starting:
        return 'Starting';
      case AutomationStatus.stopping:
        return 'Stopping';
      case AutomationStatus.error:
        return 'Error';
      case AutomationStatus.stopped:
        return 'Stopped';
    }
  }
}
