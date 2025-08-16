import 'package:enough_mail/enough_mail.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../models/email_config.dart';

class EmailService {
  Future<void> sendEmail(EmailConfig config) async {
    try {
      // Create SMTP server configuration
      final smtpServer = SmtpServer(
        config.smtpServer,
        port: config.smtpPort,
        username: config.senderEmail,
        password: config.senderPassword,
        ssl: false,
        allowInsecure: false,
      );

      // Create the email message
      final message =
          Message()
            ..from = Address(config.senderEmail)
            ..recipients.add(config.recipientEmail)
            ..subject = config.subject
            ..text =
                '${config.messageBody}\n\nSent at: ${DateTime.now().toString().substring(0, 19)}';

      // Send the email
      await send(message, smtpServer);

      // Email sent successfully
    } catch (e) {
      throw Exception('Email sending failed: $e');
    }
  }

  Future<bool> checkForReply(EmailConfig config) async {
    try {
      print('Checking for replies from ${config.recipientEmail}...');

      // Try IMAP reply detection using enough_mail
      try {
        final imapResult = await _checkImapForReplies(config);
        if (imapResult) {
          return true;
        }
      } catch (imapError) {
        print('IMAP check failed: $imapError');
      }

      // If IMAP fails, return false (no reply detected)
      return false;
    } catch (e) {
      print('Failed to check for replies: $e');
      return false;
    }
  }

  Future<bool> _checkImapForReplies(EmailConfig config) async {
    try {
      print(
        'Connecting to IMAP server ${config.imapServer}:${config.imapPort}...',
      );

      // Create IMAP client
      final imapClient = ImapClient(isLogEnabled: true);

      // Connect to IMAP server
      await imapClient.connectToServer(
        config.imapServer,
        config.imapPort,
        isSecure: true, // Use SSL/TLS
      );

      // Login
      await imapClient.login(config.senderEmail, config.senderPassword);
      print('Successfully logged in to IMAP server');

      // Select inbox
      await imapClient.selectInbox();
      print('Selected inbox');

      // Fetch recent messages to check for replies
      final fetchResult = await imapClient.fetchRecentMessages(
        messageCount: 10,
        criteria: 'BODY.PEEK[HEADER.FIELDS (FROM DATE SUBJECT)]',
      );

      if (fetchResult.messages.isNotEmpty) {
        print('Found ${fetchResult.messages.length} recent messages');

        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(hours: 24));

        for (final message in fetchResult.messages) {
          // Check if message is from the recipient
          final from = message.from;
          if (from != null &&
              from.isNotEmpty &&
              from.first.toString().contains(config.recipientEmail)) {
            final messageDate = message.decodeDate();

            if (messageDate != null && messageDate.isAfter(yesterday)) {
              print(
                'Found recent reply from ${config.recipientEmail} at $messageDate',
              );
              await imapClient.logout();
              return true;
            }
          }
        }
      } else {
        print('No recent messages found');
      }

      // Logout
      await imapClient.logout();
      return false;
    } catch (e) {
      print('IMAP check failed: $e');
      return false;
    }
  }

  // Alternative method using enough_mail high-level API
  Future<bool> checkForReplyHighLevel(EmailConfig config) async {
    try {
      print('Checking for replies using high-level API...');

      // Discover email settings
      final emailConfig = await Discover.discover(config.senderEmail);
      if (emailConfig == null) {
        print('Unable to auto-discover settings for ${config.senderEmail}');
        return false;
      }

      // Create mail account
      final account = MailAccount.fromDiscoveredSettings(
        name: 'email_automation',
        email: config.senderEmail,
        password: config.senderPassword,
        userName: config.senderEmail,
        config: emailConfig,
      );

      // Create mail client
      final mailClient = MailClient(account, isLogEnabled: true);

      try {
        await mailClient.connect();
        print('Connected to mail server');

        // Select inbox
        await mailClient.selectInbox();

        // Fetch recent messages
        final messages = await mailClient.fetchMessages(count: 10);

        if (messages.isNotEmpty) {
          final now = DateTime.now();
          final yesterday = now.subtract(const Duration(hours: 24));

          for (final message in messages) {
            // Check if message is from the recipient
            final from = message.from;
            if (from != null &&
                from.isNotEmpty &&
                from.first.toString().contains(config.recipientEmail)) {
              final messageDate = message.decodeDate();
              if (messageDate != null && messageDate.isAfter(yesterday)) {
                print('Found recent reply from ${config.recipientEmail}');
                return true;
              }
            }
          }
        }

        return false;
      } finally {
        await mailClient.disconnect();
      }
    } catch (e) {
      print('High-level API check failed: $e');
      return false;
    }
  }

  // Helper method to validate email configuration
  Future<bool> testConnection(EmailConfig config) async {
    try {
      // Test SMTP connection
      SmtpServer(
        config.smtpServer,
        port: config.smtpPort,
        username: config.senderEmail,
        password: config.senderPassword,
        ssl: false,
        allowInsecure: false,
      );

      // Test IMAP connection using enough_mail
      final imapClient = ImapClient(isLogEnabled: false);
      await imapClient.connectToServer(
        config.imapServer,
        config.imapPort,
        isSecure: true,
      );
      await imapClient.login(config.senderEmail, config.senderPassword);
      await imapClient.logout();

      // Configuration is valid if no exception is thrown
      return true;
    } catch (e) {
      throw Exception('Connection test failed: $e');
    }
  }

  // Method to get email settings for a domain
  Future<dynamic> discoverEmailSettings(String email) async {
    try {
      final settings = await Discover.discover(email);
      return settings;
    } catch (e) {
      print('Failed to discover settings for $email: $e');
      return null;
    }
  }

  // Method to send email using enough_mail SMTP
  Future<void> sendEmailWithEnoughMail(EmailConfig config) async {
    try {
      // Create SMTP client
      final smtpClient = SmtpClient('enough.de', isLogEnabled: true);

      // Connect to SMTP server
      await smtpClient.connectToServer(
        config.smtpServer,
        config.smtpPort,
        isSecure: true,
      );

      // EHLO
      await smtpClient.ehlo();

      // Authenticate
      if (smtpClient.serverInfo.supportsAuth(AuthMechanism.plain)) {
        await smtpClient.authenticate(
          config.senderEmail,
          config.senderPassword,
          AuthMechanism.plain,
        );
      } else if (smtpClient.serverInfo.supportsAuth(AuthMechanism.login)) {
        await smtpClient.authenticate(
          config.senderEmail,
          config.senderPassword,
          AuthMechanism.login,
        );
      } else {
        throw Exception('No supported authentication mechanism found');
      }

      // Build message
      final builder =
          MessageBuilder.prepareMultipartAlternativeMessage(
              plainText: config.messageBody,
              htmlText: '<p>${config.messageBody}</p>',
            )
            ..from = [MailAddress('Email Automation', config.senderEmail)]
            ..to = [MailAddress('Recipient', config.recipientEmail)]
            ..subject = config.subject;

      final mimeMessage = builder.buildMimeMessage();

      // Send message
      final sendResponse = await smtpClient.sendMessage(mimeMessage);

      if (!sendResponse.isOkStatus) {
        throw Exception('Failed to send email');
      }

      print('Email sent successfully using enough_mail');
    } catch (e) {
      throw Exception('Email sending failed: $e');
    }
  }
}
