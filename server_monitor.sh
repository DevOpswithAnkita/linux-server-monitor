#!/bin/bash

# Color codes
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RESET='\033[0m'

function header() {
  echo -e "${CYAN}===== $1 =====${RESET}"
}

function section() {
  echo -e "${YELLOW}=== $1 ===${RESET}"
}

function error_msg() {
  echo -e "${RED}$1${RESET}"
}

header "SERVER MONITORING REPORT"
date
echo ""

echo -e "${CYAN}=== SYSTEM INFORMATION ===${RESET}"

# Kernel info
echo -e "$(uname -a)"

# OS info
if [ -f /etc/os-release ]; then
  OS_NAME=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
else
  OS_NAME="Unknown"
fi
echo -e "${GREEN}OS:${RESET} $OS_NAME"

# Private IP (first non-loopback)
PRIVATE_IP=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}Private IP Address:${RESET} $PRIVATE_IP"

# Public IP (using an external service)
PUBLIC_IP=$(curl -s https://api.ipify.org)
echo -e "${GREEN}Public IP Address:${RESET} $PUBLIC_IP"

# ISP info (from public IP)
ISP=$(curl -s https://ipinfo.io/$PUBLIC_IP/org)
echo -e "${GREEN}ISP:${RESET} $ISP"

# RAM size in GB (rounded)
RAM_GB=$(free -g | awk '/Mem:/ {print $2}')
echo -e "${GREEN}RAM:${RESET} ${RAM_GB}GB"

# CPU cores and threads
if command -v lscpu >/dev/null 2>&1; then
  CPU_CORES=$(lscpu | awk '/^Core\(s\) per socket:/ {cores=$4} /^Socket\(s\):/ {sockets=$2} END {print cores*sockets}')
  CPU_THREADS=$(lscpu | awk '/^CPU\(s\):/ {print $2}')
else
  CPU_CORES=$(nproc --all)
  CPU_THREADS=$CPU_CORES
fi
echo -e "${GREEN}CPU:${RESET} ${CPU_CORES} cores, ${CPU_THREADS} threads"

# GPU info
GPU=$(lspci | grep -i nvidia | awk '{$1=$2=$3=""; print $0}' | sed 's/^ *//')
echo -e "${GREEN}GPU:${RESET} ${GPU}"

# Disk total size (sum of all disks, human readable)
DISK_SIZE=$(lsblk -d -o SIZE,TYPE | awk '$2=="disk" {sum+=$1} END {print sum "G"}')
echo -e "${GREEN}Disk Size (total):${RESET} $DISK_SIZE"

# SSD or HDD check (based on rotational flag)
SSD_OR_HDD=$(lsblk -d -o NAME,ROTA | awk '$2==0 {print $1}' | head -1)
if [ -z "$SSD_OR_HDD" ]; then
  echo -e "${RED}Disk Type:${RESET} HDD"
else
  echo -e "${GREEN}Disk Type:${RESET} SSD (at least one disk)"
fi

# IOPS - very basic check using iostat if installed
if command -v iostat >/dev/null 2>&1; then
  IOPS=$(iostat -dx 1 2 | awk 'NR>6 {sum+=$4} END {print sum " IOPS"}')
  echo -e "${GREEN}IOPS:${RESET} $IOPS"
else
  echo -e "${RED}IOPS:${RESET} iostat command not found"
fi
echo ""

echo -e "${YELLOW}=== FIREWALL STATUS ===${RESET}"

if command -v ufw >/dev/null 2>&1; then
  echo -e "${GREEN}UFW Firewall:${RESET}"
  sudo ufw status verbose
elif command -v firewall-cmd >/dev/null 2>&1; then
  echo -e "${GREEN}Firewalld (CentOS/RHEL):${RESET}"
  sudo firewall-cmd --state
  sudo firewall-cmd --list-all
elif systemctl is-active iptables >/dev/null 2>&1; then
  echo -e "${GREEN}iptables status:${RESET}"
  sudo iptables -L -n -v
else
  echo -e "${RED}Firewall:${RESET} No known firewall tool (ufw, firewalld, iptables) is active or installed"
fi

section "SYSTEM UPTIME AND LOAD"
uptime
echo ""

section "CURRENT USERS LOGGED IN"
who
echo ""

section "MEMORY USAGE"
free -h
echo ""

section "DISK USAGE (space)"
df -h
echo ""

section "DISK USAGE (inodes)"
df -i
echo ""

section "Disk LIST TOP 10 BIGGEST FILES & DIRECTORIES"
du -ah / | sort -rh | head -n 10
echo ""

section "CPU INFO"
if command -v lscpu >/dev/null 2>&1; then
  lscpu | grep -E "Model name|Socket|Core|Thread|CPU(s):" | uniq
else
  grep "model name" /proc/cpuinfo | head -1
  grep "cpu MHz" /proc/cpuinfo | head -1
fi
echo ""

# CPU temperature section
if command -v sensors >/dev/null 2>&1; then
  section "CPU TEMPERATURES"
  sensors | grep -i temp
  echo ""
fi

section "TOP PROCESSES BY MEMORY"
ps aux --sort=-%mem | head -6
echo ""

section "TOP PROCESSES BY CPU"
ps aux --sort=-%cpu | head -6
echo ""

section "ACTIVE LISTENING PORTS"
if command -v ss >/dev/null 2>&1; then
  ss -tuln | grep LISTEN
else
  netstat -tuln | grep LISTEN
fi
echo ""

section "NETWORK INTERFACES AND IP ADDRESSES"
ip addr show
echo ""

section "RECENT LOGINS"
last | head -5
echo ""

section "FAILED LOGIN ATTEMPTS"
if [ -r /var/log/auth.log ]; then
  sudo grep --color=always "Failed password" /var/log/auth.log | tail -5
elif command -v journalctl >/dev/null 2>&1; then
  sudo journalctl -u ssh.service --since "1 day ago" | grep --color=always "Failed password" | tail -5
else
  error_msg "Failed login attempts log not available."
fi
echo ""

section "SYSTEM REBOOT HISTORY"
last reboot | head -5
echo ""

section "LAST 10 ERRORS IN SYSLOG"
if [ -r /var/log/syslog ]; then
  sudo grep --color=always -i error /var/log/syslog | tail -10
elif command -v journalctl >/dev/null 2>&1; then
  sudo journalctl -p err -n 10 --no-pager
else
  error_msg "No syslog or journalctl errors found or not accessible."
fi
echo ""

section "TOP 10 FAILED/INACTIVE SYSTEMD SERVICES"
if command -v systemctl >/dev/null 2>&1; then
  systemctl list-units --state=failed --no-legend | head -10
  echo ""
  systemctl list-units --state=inactive --no-legend | head -10
else
  error_msg "systemctl command not found."
fi
echo ""

section "SYSTEM ENTROPY"
cat /proc/sys/kernel/random/entropy_avail
echo ""

section "OPEN FILES LIMIT"
ulimit -n
echo ""

section "LAST 5 CRON JOB ENTRIES"
if [ -r /var/log/cron.log ]; then
  sudo tail -5 /var/log/cron.log
elif command -v journalctl >/dev/null 2>&1; then
  sudo journalctl -u cron.service -n 5 --no-pager
else
  error_msg "No cron log found."
fi
echo ""

section "CURRENT USERS LOGGED IN"
who
echo ""


section "SYSTEM SHUTDOWN/REBOOT HISTORY"

echo -e "${GREEN}Recent shutdown and reboot events:${RESET}"
last -x | grep -E 'shutdown|reboot' | head -10
echo ""

echo -e "${GREEN}Journal logs for shutdown, poweroff, reboot, or halt:${RESET}"
journalctl | grep -iE 'shutdown|poweroff|reboot|halt' | tail -10
echo ""

echo -e "${GREEN}List of previous boots:${RESET}"
journalctl --list-boots
echo ""

echo -e "${GREEN}Auth log entries for shutdown or reboot commands:${RESET}"
if [ -r /var/log/auth.log ]; then
  sudo grep -E "(shutdown|reboot)" /var/log/auth.log | tail -10
elif command -v journalctl >/dev/null 2>&1; then
  sudo journalctl -u ssh.service --since "1 week ago" | grep -E "(shutdown|reboot)" | tail -10
else
  error_msg "Auth log not accessible or journalctl not available."
fi
echo ""

echo -e "${GREEN}Audit log entries for system shutdown and boot events:${RESET}"
if [ -d /var/log/audit ]; then
  zgrep -i 'SYSTEM_SHUTDOWN\|SYSTEM_BOOT' /var/log/audit/audit.log | tail -10
else
  error_msg "Audit logs not found in /var/log/audit."
fi
echo ""

header "END OF REPORT"
