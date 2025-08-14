import email
import imaplib
import json
import logging
import os
import smtplib
import time
from datetime import datetime
from email.header import decode_header
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

import schedule

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.FileHandler("email_automation.log"), logging.StreamHandler()],
)


class EmailAutomation:
    def __init__(self, config_file="config.json"):
        """Initialize the email automation system."""
        self.config = self.load_config(config_file)
        self.smtp_server = None
        self.imap_server = None
        self.running = True
        self.last_email_time = None

    def load_config(self, config_file):
        """Load configuration from JSON file."""
        if not os.path.exists(config_file):
            # Create default config file
            default_config = {
                "gmail_username": "your_email@gmail.com",
                "gmail_password": "your_app_password",
                "recipient_email": "recipient@example.com",
                "subject": "Automated Email - Waiting for Reply",
                "message_file": "message_template.txt",
                "check_interval_minutes": 120,
                "smtp_server": "smtp.gmail.com",
                "smtp_port": 587,
                "imap_server": "imap.gmail.com",
                "imap_port": 993,
            }
            with open(config_file, "w", encoding="utf-8") as f:
                json.dump(default_config, f, indent=4)
            logging.info(f"Created default config file: {config_file}")
            logging.info(
                "Please update the config file with your Gmail credentials and settings."
            )
            return default_config

        with open(config_file, "r", encoding="utf-8") as f:
            return json.load(f)

    def load_message_template(self):
        """Load the email message template from file."""
        try:
            message_file = self.config.get("message_file", "message_template.txt")
            if not os.path.exists(message_file):
                # Create default message file if it doesn't exist
                default_message = """Hello,

This is an automated message. I'm reaching out regarding an important matter and wanted to ensure you received this communication.

Please reply to this email to confirm receipt and stop receiving these automated reminders.

Thank you for your time and attention.

Best regards"""
                with open(message_file, "w", encoding="utf-8") as f:
                    f.write(default_message)
                logging.info(f"Created default message template: {message_file}")
                return default_message

            with open(message_file, "r", encoding="utf-8") as f:
                return f.read().strip()
        except Exception as e:
            logging.error(f"Failed to load message template: {str(e)}")
            return "This is an automated message. Please reply to stop receiving these emails."

    def setup_smtp_connection(self):
        """Set up SMTP connection for sending emails."""
        try:
            self.smtp_server = smtplib.SMTP(
                self.config["smtp_server"], self.config["smtp_port"]
            )
            self.smtp_server.starttls()
            self.smtp_server.login(
                self.config["gmail_username"], self.config["gmail_password"]
            )
            logging.info("SMTP connection established successfully")
            return True
        except Exception as e:
            logging.error(f"Failed to establish SMTP connection: {str(e)}")
            return False

    def setup_imap_connection(self):
        """Set up IMAP connection for checking replies."""
        try:
            self.imap_server = imaplib.IMAP4_SSL(
                self.config["imap_server"], self.config["imap_port"]
            )
            self.imap_server.login(
                self.config["gmail_username"], self.config["gmail_password"]
            )
            logging.info("IMAP connection established successfully")
            return True
        except Exception as e:
            logging.error(f"Failed to establish IMAP connection: {str(e)}")
            return False

    def send_email(self):
        """Send an email to the specified recipient."""
        try:
            if not self.smtp_server:
                if not self.setup_smtp_connection():
                    return False

            # Create message
            msg = MIMEMultipart()
            msg["From"] = self.config["gmail_username"]
            msg["To"] = self.config["recipient_email"]
            msg["Subject"] = self.config["subject"]

            # Load message template and add timestamp
            message_template = self.load_message_template()
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            body = f"{message_template}\n\nSent at: {timestamp}"
            msg.attach(MIMEText(body, "plain"))

            # Send email
            text = msg.as_string()
            self.smtp_server.sendmail(
                self.config["gmail_username"], self.config["recipient_email"], text
            )

            self.last_email_time = datetime.now()
            logging.info(
                f"Email sent successfully to {self.config['recipient_email']} at {timestamp}"
            )
            return True

        except Exception as e:
            logging.error(f"Failed to send email: {str(e)}")
            # Try to reconnect
            self.smtp_server = None
            return False

    def check_for_replies(self):
        """Check for replies from the recipient."""
        try:
            if not self.imap_server:
                if not self.setup_imap_connection():
                    return False

            # Select inbox
            self.imap_server.select("INBOX")

            # Search for emails from the recipient
            search_criteria = f'FROM "{self.config["recipient_email"]}"'

            # If we've sent an email, only check for replies after that time
            if self.last_email_time:
                since_date = self.last_email_time.strftime("%d-%b-%Y")
                search_criteria += f' SINCE "{since_date}"'

            status, messages = self.imap_server.search(None, search_criteria)

            if status == "OK" and messages[0]:
                email_ids = messages[0].split()

                # Check if any emails are newer than our last sent email
                for email_id in email_ids:
                    status, msg_data = self.imap_server.fetch(email_id, "(RFC822)")
                    if status == "OK":
                        email_message = email.message_from_bytes(msg_data[0][1])

                        # Get email date
                        date_str = email_message.get("Date")
                        if date_str:
                            try:
                                email_date = email.utils.parsedate_to_datetime(date_str)

                                # If email is newer than our last sent email, we have a reply
                                if (
                                    self.last_email_time
                                    and email_date > self.last_email_time
                                ):
                                    subject = decode_header(
                                        email_message.get("Subject", "")
                                    )[0][0]
                                    if isinstance(subject, bytes):
                                        subject = subject.decode()

                                    logging.info(
                                        f"Reply received from {self.config['recipient_email']}"
                                    )
                                    logging.info(f"Reply subject: {subject}")
                                    logging.info(f"Reply date: {email_date}")
                                    return True
                            except Exception as e:
                                logging.warning(f"Error parsing email date: {str(e)}")

            return False

        except Exception as e:
            logging.error(f"Failed to check for replies: {str(e)}")
            # Try to reconnect
            self.imap_server = None
            return False

    def cleanup_connections(self):
        """Clean up SMTP and IMAP connections."""
        try:
            if self.smtp_server:
                self.smtp_server.quit()
                self.smtp_server = None
            if self.imap_server:
                self.imap_server.logout()
                self.imap_server = None
            logging.info("Connections cleaned up successfully")
        except Exception as e:
            logging.error(f"Error during cleanup: {str(e)}")

    def scheduled_email_job(self):
        """Job to be executed at the specified interval."""
        if not self.running:
            return

        logging.info("Checking for replies before sending email...")

        # Check for replies first
        if self.check_for_replies():
            logging.info("Reply detected! Stopping email automation.")
            self.stop()
            return

        # If no reply, send email
        logging.info("No reply detected. Sending email...")
        self.send_email()

    def start(self):
        """Start the email automation process."""
        logging.info("Starting email automation...")
        logging.info(f"Target recipient: {self.config['recipient_email']}")
        logging.info(f"Check interval: {self.config['check_interval_minutes']} minutes")

        # Send initial email
        if self.send_email():
            logging.info("Initial email sent successfully")
        else:
            logging.error(
                "Failed to send initial email. Please check your configuration."
            )
            return

        # Schedule the job at the specified interval
        schedule.every(self.config["check_interval_minutes"]).minutes.do(
            self.scheduled_email_job
        )

        logging.info("Email automation started. Press Ctrl+C to stop.")

        try:
            while self.running:
                schedule.run_pending()
                time.sleep(60)  # Check every minute
        except KeyboardInterrupt:
            logging.info("Keyboard interrupt received. Stopping...")
        finally:
            self.stop()

    def stop(self):
        """Stop the email automation process."""
        self.running = False
        schedule.clear()
        self.cleanup_connections()
        logging.info("Email automation stopped.")


def main():
    """Main function to run the email automation."""
    automation = EmailAutomation()

    # Validate configuration
    if automation.config["gmail_username"] == "your_email@gmail.com":
        logging.error("Please update the config.json file with your Gmail credentials.")
        logging.error(
            "Make sure to use an App Password for Gmail, not your regular password."
        )
        return

    automation.start()


if __name__ == "__main__":
    main()
