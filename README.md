# Server Monitoring Script

A comprehensive bash script for monitoring and reporting system information, performance metrics, and security status on Linux servers.

## Features

- **System Information**: OS details, IP addresses, ISP information, hardware specs
- **Performance Monitoring**: CPU usage, memory usage, disk usage, top processes
- **Security Status**: Firewall status, failed login attempts, listening ports
- **System Health**: Service status, error logs, system uptime, temperature monitoring
- **Historical Data**: Login history, reboot history, shutdown events
- **Network Information**: Active connections, network interfaces
- **Resource Limits**: Open files limit, system entropy

## Prerequisites

- Linux-based operating system (Ubuntu, CentOS, RHEL, Debian, etc.)
- Bash shell
- Root or sudo privileges (required for some operations)

### Optional Dependencies

The script will work without these but provides enhanced functionality when available:
- `lscpu` - For detailed CPU information
- `sensors` - For temperature monitoring
- `iostat` - For IOPS measurements
- `ss` or `netstat` - For network connection monitoring
- `systemctl` - For systemd service monitoring

## Installation

1. Clone this repository:
```bash
git clone https://github.com/DevOpswithAnkita/linux-server-monitor.git
cd linux-server-monitor
```

2. Make the script executable:
```bash
chmod +x server_monitor.sh
```

## Usage

### Basic Usage
```bash
./server_monitor.sh
```

### Run with sudo for complete information
```bash
sudo ./server_monitor.sh
```

### Save output to file
```bash
sudo ./server_monitor.sh > server_report_$(date +%Y%m%d_%H%M%S).txt
```

### Schedule regular monitoring with cron
```bash
# Edit crontab
crontab -e

# Add this line to run every hour
0 * * * * /path/to/server_monitor.sh > /var/log/server_monitor_$(date +\%Y\%m\%d_\%H\%M\%S).log 2>&1
```

## Output Sections

The script generates a comprehensive report with the following sections:

### System Information
- Kernel and OS details
- Private and public IP addresses
- ISP information
- Hardware specifications (RAM, CPU, GPU, Disk)

### Security Monitoring
- Firewall status (UFW, firewalld, or iptables)
- Failed login attempts
- Recent login history
- Active listening ports

### Performance Metrics
- System uptime and load average
- Memory usage statistics
- Disk space and inode usage
- Top processes by CPU and memory usage
- CPU temperature (if sensors available)

### System Health
- Failed/inactive systemd services
- Recent system errors
- System entropy levels
- Open file limits

### Historical Data
- System reboot history
- Shutdown/poweroff events
- Boot history
- Cron job execution logs

## Sample Output

```
===== SERVER MONITORING REPORT =====
Thu May 22 10:30:45 UTC 2025

=== SYSTEM INFORMATION ===
Linux server01 5.4.0-74-generic #83-Ubuntu SMP Sat May 8 02:35:39 UTC 2021 x86_64 x86_64 x86_64 GNU/Linux
OS: Ubuntu 20.04.2 LTS
Private IP Address: 192.168.1.100
Public IP Address: 203.0.113.1
ISP: Example ISP Inc.
RAM: 16GB
CPU: 8 cores, 16 threads
...
```

## Security Considerations

- The script requires sudo privileges for accessing certain system logs and security information
- Public IP detection uses external services (ipify.org and ipinfo.io)
- Some sensitive information like IP addresses and ISP details are included in the output
- Review the output before sharing or storing in public locations

## Customization

You can modify the script to:
- Add or remove monitoring sections
- Change color schemes by modifying the color variables
- Adjust the number of displayed items (currently shows top 10 for most sections)
- Modify external IP detection services

## Troubleshooting

### Common Issues

1. **Permission denied errors**: Run with sudo privileges
2. **Command not found**: Install missing dependencies or the script will skip those sections
3. **Network timeouts**: Check internet connectivity for public IP detection
4. **Audit log not found**: See audit log setup instructions below

### Error Messages

The script handles missing commands gracefully and will display appropriate error messages for:
- Missing log files
- Unavailable system tools
- Network connectivity issues

### Audit Log Setup

If you encounter "Audit logs not found" errors, you need to install and configure the audit daemon:

```bash
# Update package list
sudo apt update

# Install auditd
sudo apt install auditd -y

# Add audit rules for system shutdown and boot events
sudo auditctl -a always,exit -F arch=b64 -S reboot -S shutdown -k system_shutdown
sudo auditctl -a always,exit -F arch=b64 -S init_module -S delete_module -k system_boot

# Start and enable auditd service
sudo systemctl start auditd
sudo systemctl enable auditd

# Verify audit rules are active
sudo auditctl -l
```

**Note**: After setting up audit rules, you'll need to wait for some system events to occur before the audit logs will show meaningful data.

This script is provided as-is for system monitoring purposes. Always review the output before sharing, as it may contain sensitive system information. Use at your own risk and ensure you have proper authorization before running on production systems.


