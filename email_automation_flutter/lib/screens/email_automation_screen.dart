import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/email_automation_provider.dart';

class EmailAutomationScreen extends StatefulWidget {
  const EmailAutomationScreen({super.key});

  @override
  State<EmailAutomationScreen> createState() => _EmailAutomationScreenState();
}

class _EmailAutomationScreenState extends State<EmailAutomationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  // Sender credentials are now managed by auth provider
  final _recipientEmailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _intervalController = TextEditingController();

  // Password visibility removed since credentials are handled by auth provider
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConfiguration();
      _refreshCredentials();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _recipientEmailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  void _loadConfiguration() {
    final provider = Provider.of<EmailAutomationProvider>(
      context,
      listen: false,
    );
    final config = provider.config;

    _recipientEmailController.text = config.recipientEmail;
    _subjectController.text = config.subject;
    _messageController.text = config.messageBody;
    _intervalController.text = config.intervalMinutes.toString();
  }

  void _refreshCredentials() {
    final provider = Provider.of<EmailAutomationProvider>(
      context,
      listen: false,
    );
    provider.refreshCredentials();
  }

  void _saveConfiguration() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<EmailAutomationProvider>(
        context,
        listen: false,
      );
      final newConfig = provider.config.copyWith(
        recipientEmail: _recipientEmailController.text.trim(),
        subject: _subjectController.text.trim(),
        messageBody: _messageController.text.trim(),
        intervalMinutes: int.tryParse(_intervalController.text) ?? 120,
      );

      provider.updateConfig(newConfig);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
              const Color(0xFF6366F1).withValues(alpha: 0.02),
              const Color(0xFF8B5CF6).withValues(alpha: 0.02),
              const Color(0xFFEC4899).withValues(alpha: 0.02),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 100,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.white.withValues(alpha: 0.95),
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        MdiIcons.emailOutline,
                        size: 24,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Email Automation',
                      style: TextStyle(
                        color: Color(0xFF1F2937),
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF6366F1).withValues(alpha: 0.1),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      MdiIcons.contentSave,
                      color: const Color(0xFF10B981),
                    ),
                    onPressed: _saveConfiguration,
                    tooltip: 'Save Configuration',
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      MdiIcons.refresh,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      Provider.of<EmailAutomationProvider>(
                        context,
                        listen: false,
                      ).resetStats();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Statistics reset'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                    tooltip: 'Reset Statistics',
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: 24),
                        _buildConfigurationCard(),
                        const SizedBox(height: 24),
                        _buildControlCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Consumer<EmailAutomationProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFF6366F1).withValues(alpha: 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        MdiIcons.chartLine,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Status',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildStatusIndicator(provider),
                if (provider.errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFEF4444).withValues(alpha: 0.1),
                          const Color(0xFFEF4444).withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            MdiIcons.alertCircle,
                            color: const Color(0xFFEF4444),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            provider.errorMessage,
                            style: TextStyle(
                              color: const Color(0xFFEF4444),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Emails Sent',
                        provider.emailsSent.toString(),
                        MdiIcons.emailOutline,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        'Last Email',
                        provider.lastEmailSent != null
                            ? provider.lastEmailSent!.toString().substring(
                              11,
                              19,
                            )
                            : 'Never',
                        MdiIcons.clock,
                        Colors.green,
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

  Widget _buildStatusIndicator(EmailAutomationProvider provider) {
    Color statusColor;
    IconData statusIcon;
    Widget statusWidget;

    switch (provider.status) {
      case AutomationStatus.running:
        statusColor = const Color(0xFF10B981);
        statusIcon = MdiIcons.play;
        statusWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                statusColor.withValues(alpha: 0.1),
                statusColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              SpinKitThreeBounce(color: statusColor, size: 12),
              const SizedBox(width: 8),
              Text(
                'Running',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
        break;
      case AutomationStatus.starting:
        statusColor = const Color(0xFFF59E0B);
        statusIcon = MdiIcons.loading;
        statusWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                statusColor.withValues(alpha: 0.1),
                statusColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              SpinKitRing(color: statusColor, size: 12, lineWidth: 2),
              const SizedBox(width: 8),
              Text(
                'Starting...',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
        break;
      case AutomationStatus.stopping:
        statusColor = const Color(0xFFF59E0B);
        statusIcon = MdiIcons.stop;
        statusWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                statusColor.withValues(alpha: 0.1),
                statusColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              SpinKitRing(color: statusColor, size: 12, lineWidth: 2),
              const SizedBox(width: 8),
              Text(
                'Stopping...',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
        break;
      case AutomationStatus.error:
        statusColor = const Color(0xFFEF4444);
        statusIcon = MdiIcons.alertCircle;
        statusWidget = Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 16),
            const SizedBox(width: 12),
            Text(
              'Error',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        );
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = MdiIcons.stop;
        statusWidget = Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 16),
            const SizedBox(width: 12),
            Text(
              'Stopped',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        statusWidget,
        const SizedBox(height: 8),
        Text(
          provider.statusMessage,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Color.fromARGB(
                    255,
                    (color.r * 0.7).round(),
                    (color.g * 0.7).round(),
                    (color.b * 0.7).round(),
                  ),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Color.fromARGB(
                255,
                (color.r * 0.8).round(),
                (color.g * 0.8).round(),
                (color.b * 0.8).round(),
              ),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  MdiIcons.cog,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Configuration',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildEmailSection(),
            const SizedBox(height: 24),
            _buildMessageSection(),
            const SizedBox(height: 24),
            _buildIntervalSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            // Show current Gmail account
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(MdiIcons.checkCircle, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sending from:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          authProvider.userEmail ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _recipientEmailController,
              decoration: InputDecoration(
                labelText: 'Recipient Email',
                hintText: 'recipient@example.com',
                prefixIcon: Icon(MdiIcons.accountCircle),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter recipient email address';
                }
                if (!EmailValidator.validate(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Message Configuration',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _subjectController,
          decoration: InputDecoration(
            labelText: 'Email Subject',
            hintText: 'Enter email subject',
            prefixIcon: Icon(MdiIcons.formatTitle),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter email subject';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _messageController,
          decoration: InputDecoration(
            labelText: 'Message Body',
            hintText: 'Enter your message here...',
            prefixIcon: Icon(MdiIcons.messageText),
            alignLabelWithHint: true,
          ),
          maxLines: 12,
          minLines: 8,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter message body';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildIntervalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Automation Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _intervalController,
          decoration: InputDecoration(
            labelText: 'Interval (minutes)',
            hintText: 'Enter interval in minutes',
            prefixIcon: Icon(MdiIcons.timerSand),
            suffixText: 'min',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter interval in minutes';
            }
            final interval = int.tryParse(value);
            if (interval == null || interval < 1) {
              return 'Please enter a valid interval (minimum 1 minute)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildControlCard() {
    return Consumer<EmailAutomationProvider>(
      builder: (context, provider, child) {
        final isRunning = provider.status == AutomationStatus.running;
        final isStarting = provider.status == AutomationStatus.starting;
        final isStopping = provider.status == AutomationStatus.stopping;
        final canStart =
            provider.status == AutomationStatus.stopped ||
            provider.status == AutomationStatus.error;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      MdiIcons.playCircle,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Control',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            canStart
                                ? () {
                                  provider.startAutomation(
                                    recipientEmail:
                                        _recipientEmailController.text.trim(),
                                    subject: _subjectController.text.trim(),
                                    messageBody: _messageController.text.trim(),
                                    intervalMinutes:
                                        int.tryParse(
                                          _intervalController.text,
                                        ) ??
                                        120,
                                  );
                                }
                                : null,
                        icon:
                            isStarting
                                ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                                : Icon(MdiIcons.play),
                        label: Text(
                          isStarting ? 'Starting...' : 'Start Automation',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            (isRunning || isStarting)
                                ? () {
                                  provider.stopAutomation();
                                }
                                : null,
                        icon:
                            isStopping
                                ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.onError,
                                    ),
                                  ),
                                )
                                : Icon(MdiIcons.stop),
                        label: Text(
                          isStopping ? 'Stopping...' : 'Stop Automation',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
}
