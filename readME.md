

1. Open a new service file using a text editor, such as `nano`, with root privileges:
```bash
sudo nano /etc/systemd/system/my_script.service
```
1. Add the following content to the service file:
```makefile
[Unit]
Description=My Python Script
After=network.target

[Service]
User=root
WorkingDirectory=/root
ExecStart=/bin/bash -c 'source /root/dev-env/bin/activate && python /root/test.py'
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=my_script

[Install]
WantedBy=multi-user.target
```
This service file configures `systemd` to run your script as the root user, activate the `dev-env` virtual environment, and restart it if it fails (with a 10-second delay). The output is logged to the system log.

1. Save the service file and exit the text editor.
2. Reload the `systemd` daemon to load the new service file:
```bash
sudo systemctl daemon-reload
```
1. Enable the service to start automatically on boot:
```bash
sudo systemctl enable my_script.service
```
1. Start the service:
```bash
sudo systemctl start my_script.service
```
1. Check the status of the service:
```bash
sudo systemctl status my_script.service
```
Now, your script will be automatically restarted by `systemd` if it fails or crashes. You can also view the script's logs using the `journalctl` command:
```bash
journalctl -u my_script.service
```
