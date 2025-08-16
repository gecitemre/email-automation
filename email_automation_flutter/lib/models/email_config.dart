class EmailConfig {
  String senderEmail;
  String senderPassword;
  String recipientEmail;
  String subject;
  String messageBody;
  int intervalMinutes;
  String smtpServer;
  int smtpPort;
  String imapServer;
  int imapPort;

  EmailConfig({
    this.senderEmail = '',
    this.senderPassword = '',
    this.recipientEmail = '',
    this.subject = 'Automated Email - Waiting for Reply',
    this.messageBody =
        'Hello,\n\nThis is an automated message. Please reply to stop receiving these emails.\n\nBest regards',
    this.intervalMinutes = 120,
    this.smtpServer = 'smtp.gmail.com',
    this.smtpPort = 587,
    this.imapServer = 'imap.gmail.com',
    this.imapPort = 993,
  });

  bool isValid() {
    return senderEmail.isNotEmpty &&
        senderPassword.isNotEmpty &&
        recipientEmail.isNotEmpty &&
        subject.isNotEmpty &&
        messageBody.isNotEmpty &&
        intervalMinutes > 0;
  }

  EmailConfig copyWith({
    String? senderEmail,
    String? senderPassword,
    String? recipientEmail,
    String? subject,
    String? messageBody,
    int? intervalMinutes,
    String? smtpServer,
    int? smtpPort,
    String? imapServer,
    int? imapPort,
  }) {
    return EmailConfig(
      senderEmail: senderEmail ?? this.senderEmail,
      senderPassword: senderPassword ?? this.senderPassword,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      subject: subject ?? this.subject,
      messageBody: messageBody ?? this.messageBody,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      smtpServer: smtpServer ?? this.smtpServer,
      smtpPort: smtpPort ?? this.smtpPort,
      imapServer: imapServer ?? this.imapServer,
      imapPort: imapPort ?? this.imapPort,
    );
  }
}
