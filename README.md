# Email Automation Tool

This Python program automatically sends emails to a specific recipient at configurable intervals (in minutes) until they reply, using your Gmail account.

## Features

- Sends automated emails via Gmail SMTP
- Monitors for replies using Gmail IMAP
- Stops automatically when a reply is received
- Configurable email content and intervals
- Comprehensive logging
- Error handling and automatic reconnection

## Requirements

- Python 3.6+
- Gmail account with App Password enabled
- Internet connection

## Setup Instructions

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Enable Gmail App Password

1. Go to your Google Account settings: https://myaccount.google.com/
2. Navigate to Security → 2-Step Verification
3. Enable 2-Step Verification if not already enabled
4. Go to Security → App passwords
5. Generate a new app password for "Mail"
6. Copy the 16-character password (this will be used in config.json)

### 3. Configure the Application

Edit the `config.json` file with your settings:

```json
{
    "gmail_username": "your_email@gmail.com",
    "gmail_password": "your_16_character_app_password",
    "recipient_email": "recipient@example.com",
    "subject": "Automated Email - Waiting for Reply",
    "message_file": "message_template.txt",
    "check_interval_minutes": 120,
    "smtp_server": "smtp.gmail.com",
    "smtp_port": 587,
    "imap_server": "imap.gmail.com",
    "imap_port": 993
}
```

**Important**: 
- Use your Gmail App Password, NOT your regular Gmail password
- Make sure the recipient email is correct
- Customize the subject and message template file as needed

### 4. Customize the Email Message (Optional)

Edit `message_template.txt` to customize your email content:

```
Hello,

This is an automated message. I'm reaching out regarding an important matter and wanted to ensure you received this communication.

Please reply to this email to confirm receipt and stop receiving these automated reminders.

Thank you for your time and attention.

Best regards
```

### 5. Run the Program

```bash
python email_automation.py
```

## How It Works

1. **Initial Email**: Sends the first email immediately upon startup
2. **Monitoring**: Checks for replies from the recipient at the specified interval
3. **Automated Sending**: If no reply is detected, sends another email
4. **Auto-Stop**: Stops automatically when a reply is received
5. **Logging**: All activities are logged to `email_automation.log`

## Configuration Options

- `gmail_username`: Your Gmail address
- `gmail_password`: Your Gmail App Password (16 characters)
- `recipient_email`: Email address to send automated emails to
- `subject`: Subject line for the automated emails
- `message_file`: Path to the text file containing the email message template
- `check_interval_minutes`: Minutes between email sends (default: 120 = 2 hours)
  - Examples: 30 (30 minutes), 60 (1 hour), 120 (2 hours), 240 (4 hours)
- `smtp_server`: Gmail SMTP server (default: smtp.gmail.com)
- `smtp_port`: Gmail SMTP port (default: 587)
- `imap_server`: Gmail IMAP server (default: imap.gmail.com)
- `imap_port`: Gmail IMAP port (default: 993)

## Stopping the Program

- **Automatic**: The program stops automatically when the recipient replies
- **Manual**: Press `Ctrl+C` to stop the program manually

## Logging

The program creates detailed logs in `email_automation.log` including:
- Email sending status
- Reply detection
- Connection status
- Error messages
- Timestamps for all activities

## Troubleshooting

### Common Issues

1. **Authentication Error**
   - Make sure you're using an App Password, not your regular Gmail password
   - Verify 2-Step Verification is enabled on your Google account

2. **Connection Timeout**
   - Check your internet connection
   - Verify Gmail SMTP/IMAP settings
   - Check if your firewall is blocking the connection

3. **Email Not Sending**
   - Verify the recipient email address is correct
   - Check the log file for specific error messages
   - Ensure your Gmail account has sufficient sending limits

4. **Reply Not Detected**
   - The program only checks for replies from the exact recipient email
   - Make sure the reply is sent to your Gmail inbox
   - Check spam folder for replies

### Security Notes

- Never share your Gmail App Password
- Store configuration files securely
- Consider using environment variables for sensitive information in production
- The program only reads emails from the specified recipient for security

## Support

If you encounter any issues:
1. Check the log file (`email_automation.log`) for error details
2. Verify your Gmail App Password is correct
3. Ensure your internet connection is stable
4. Make sure the recipient email address is accurate
