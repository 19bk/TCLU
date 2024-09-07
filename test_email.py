import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Email credentials
EMAIL_ADDRESS = "onchainurchin@gmail.com"
EMAIL_PASSWORD = "bqjt ulmj nsgk drat"
RECIPIENT_EMAIL = "onchainurchin@gmail.com"

# Email details
subject = 'Subject of the email'
body = 'This is the body of the email.'

# Set up the MIME
msg = MIMEMultipart()
msg['From'] = EMAIL_ADDRESS
msg['To'] = RECIPIENT_EMAIL
msg['Subject'] = subject

# Attach the email body
msg.attach(MIMEText(body, 'plain'))

try:
    # Connect to Gmail SMTP server and send email
    server = smtplib.SMTP('smtp.gmail.com', 587)
    server.starttls()  # Secure the connection
    server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
    text = msg.as_string()
    server.sendmail(EMAIL_ADDRESS, RECIPIENT_EMAIL, text)
    print("Email sent successfully")
except Exception as e:
    print(f"Failed to send email: {e}")
finally:
    server.quit()
