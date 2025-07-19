#!/bin/bash

# GenSyn RL-Swarm - Google Cloud Unbannable Deployment Script
# Optimized for n2-standard-8 (8 vCPU, 32GB RAM)
# Based on 0xmoei guide: https://github.com/0xmoei/gensyn-ai

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GENSYN_DIR="/opt/gensyn-rl-swarm"
LOG_DIR="/var/log/gensyn"
BACKUP_DIR="/opt/backups/gensyn"
SWARM_USER="gensyn"
SWARM_GROUP="gensyn"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root"
   exit 1
fi

print_header "GenSyn RL-Swarm - Google Cloud Unbannable Deployment"
print_status "Starting deployment for n2-standard-8 instance..."

# Update system
print_status "Updating system packages..."
apt-get update && apt-get upgrade -y

# Install essential packages
print_status "Installing essential packages..."
apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    htop \
    iotop \
    nethogs \
    unzip \
    screen \
    nano \
    vim \
    python3-venv \
    python3-pip \
    python3-dev \
    ufw \
    fail2ban \
    logrotate \
    cron \
    supervisor \
    nginx \
    certbot \
    python3-certbot-nginx

# Install Python 3.11
print_status "Installing Python 3.11..."
add-apt-repository ppa:deadsnakes/ppa -y
apt-get update
apt-get install -y python3.11 python3.11-pip python3.11-venv python3.11-dev

# Install Node.js 18
print_status "Installing Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
npm install -g yarn

# Create user and directories
print_status "Creating user and directories..."
useradd -m -s /bin/bash $SWARM_USER || true
usermod -aG sudo $SWARM_USER

mkdir -p $GENSYN_DIR
mkdir -p $LOG_DIR
mkdir -p $BACKUP_DIR
chown -R $SWARM_USER:$SWARM_GROUP $GENSYN_DIR
chown -R $SWARM_USER:$SWARM_GROUP $LOG_DIR
chown -R $SWARM_USER:$SWARM_GROUP $BACKUP_DIR

# Setup GenSyn RL-Swarm
print_status "Setting up GenSyn RL-Swarm..."
cd $GENSYN_DIR

# Clone repository
if [ ! -d ".git" ]; then
    sudo -u $SWARM_USER git clone https://github.com/gensyn-ai/rl-swarm.git .
fi

# Create Python virtual environment
sudo -u $SWARM_USER python3.11 -m venv .venv

# Install Python dependencies
print_status "Installing Python dependencies..."
sudo -u $SWARM_USER bash -c "source .venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"

# Install Node.js dependencies
print_status "Installing Node.js dependencies..."
cd modal-login
sudo -u $SWARM_USER yarn install
cd ..

# Create necessary directories
sudo -u $SWARM_USER mkdir -p logs models data

# Apply fixes from 0xmoei guide
print_status "Applying configuration fixes..."

# Fix 1: CPU Configuration
if [ -f "hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml" ]; then
    sed -i 's/bf16: true/bf16: false/' hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml
    sed -i 's/max_steps: [0-9]*/max_steps: 5/' hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml
fi

# Fix 2: Daemon timeout fix
DAEMON_FILE=$(sudo -u $SWARM_USER bash -c "source .venv/bin/activate && python3 -c \"import hivemind.p2p.p2p_daemon as m; print(m.__file__)\"" 2>/dev/null || echo "")
if [ -n "$DAEMON_FILE" ] && [ -f "$DAEMON_FILE" ]; then
    sed -i 's/startup_timeout: float = 15/startup_timeout: float = 120/' "$DAEMON_FILE"
fi

# Create advanced anti-suspension system
print_status "Creating advanced anti-suspension system..."

# Create keep-alive script with multiple strategies
cat > $GENSYN_DIR/keep-alive.sh << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/gensyn/keep-alive.log"
HEALTH_CHECK_URLS=(
    "https://www.google.com"
    "https://www.cloudflare.com"
    "https://httpbin.org/get"
    "https://api.github.com"
)

# Function to log with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Function to check if GenSyn is running
check_gensyn() {
    if ! screen -list | grep -q "swarm"; then
        log_message "WARNING: GenSyn screen session not found, restarting..."
        /opt/gensyn-rl-swarm/start-swarm.sh
        return 1
    fi
    return 0
}

# Function to simulate normal user activity
simulate_activity() {
    # Random file operations
    touch /tmp/activity_$(date +%s)
    echo "Activity check $(date)" >> /tmp/activity.log
    
    # Random network activity
    for url in "${HEALTH_CHECK_URLS[@]}"; do
        curl -s --max-time 10 "$url" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            log_message "Network check successful: $url"
            break
        fi
    done
    
    # Random system activity
    df -h > /dev/null
    free -h > /dev/null
    uptime > /dev/null
}

# Function to check system resources
check_resources() {
    CPU_USAGE=$(top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1)
    MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.2f", $3/$2 * 100.0)}')
    DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    log_message "System Resources - CPU: ${CPU_USAGE}%, Memory: ${MEMORY_USAGE}%, Disk: ${DISK_USAGE}%"
    
    # Alert if resources are high
    if (( $(echo "$CPU_USAGE > 90" | bc -l) )); then
        log_message "WARNING: High CPU usage detected: ${CPU_USAGE}%"
    fi
    
    if (( $(echo "$MEMORY_USAGE > 90" | bc -l) )); then
        log_message "WARNING: High memory usage detected: ${MEMORY_USAGE}%"
    fi
    
    if [ "$DISK_USAGE" -gt 90 ]; then
        log_message "WARNING: High disk usage detected: ${DISK_USAGE}%"
    fi
}

# Main loop
while true; do
    log_message "Keep-alive cycle started"
    
    # Check GenSyn status
    check_gensyn
    
    # Simulate normal activity
    simulate_activity
    
    # Check system resources
    check_resources
    
    # Random sleep between 2-8 minutes to avoid detection patterns
    SLEEP_TIME=$((120 + RANDOM % 360))
    log_message "Sleeping for ${SLEEP_TIME} seconds"
    sleep $SLEEP_TIME
done
EOF

chmod +x $GENSYN_DIR/keep-alive.sh

# Create resource monitoring script
cat > $GENSYN_DIR/monitor.sh << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/gensyn/monitor.log"
ALERT_LOG="/var/log/gensyn/alerts.log"

# Function to log with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

log_alert() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ALERT: $1" >> $ALERT_LOG
}

# Function to check processes
check_processes() {
    # Check GenSyn processes
    GENSYN_PROCESSES=$(ps aux | grep -E "(python|node)" | grep -v grep | wc -l)
    log_message "Active GenSyn processes: $GENSYN_PROCESSES"
    
    if [ "$GENSYN_PROCESSES" -lt 2 ]; then
        log_alert "Low number of GenSyn processes detected"
    fi
    
    # Check screen sessions
    SCREEN_SESSIONS=$(screen -ls | grep swarm | wc -l)
    log_message "Screen sessions: $SCREEN_SESSIONS"
    
    if [ "$SCREEN_SESSIONS" -eq 0 ]; then
        log_alert "No GenSyn screen session found"
    fi
}

# Function to check network connectivity
check_network() {
    # Test multiple endpoints
    ENDPOINTS=("8.8.8.8" "1.1.1.1" "208.67.222.222")
    
    for endpoint in "${ENDPOINTS[@]}"; do
        if ping -c 1 -W 5 "$endpoint" > /dev/null 2>&1; then
            log_message "Network connectivity OK: $endpoint"
            return 0
        fi
    done
    
    log_alert "Network connectivity issues detected"
    return 1
}

# Function to check disk space
check_disk() {
    DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    log_message "Disk usage: ${DISK_USAGE}%"
    
    if [ "$DISK_USAGE" -gt 85 ]; then
        log_alert "High disk usage: ${DISK_USAGE}%"
    fi
}

# Function to check memory
check_memory() {
    MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.2f", $3/$2 * 100.0)}')
    log_message "Memory usage: ${MEMORY_USAGE}%"
    
    if (( $(echo "$MEMORY_USAGE > 85" | bc -l) )); then
        log_alert "High memory usage: ${MEMORY_USAGE}%"
    fi
}

# Function to check CPU
check_cpu() {
    CPU_USAGE=$(top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1)
    log_message "CPU usage: ${CPU_USAGE}%"
    
    if (( $(echo "$CPU_USAGE > 90" | bc -l) )); then
        log_alert "High CPU usage: ${CPU_USAGE}%"
    fi
}

# Main monitoring loop
while true; do
    log_message "=== Monitoring cycle started ==="
    
    check_processes
    check_network
    check_disk
    check_memory
    check_cpu
    
    log_message "=== Monitoring cycle completed ==="
    
    # Sleep for 5 minutes
    sleep 300
done
EOF

chmod +x $GENSYN_DIR/monitor.sh

# Create startup script
cat > $GENSYN_DIR/start-swarm.sh << 'EOF'
#!/bin/bash

cd /opt/gensyn-rl-swarm

# Kill existing screen session if exists
screen -XS swarm quit 2>/dev/null || true

# Wait a moment
sleep 2

# Start new screen session with optimized settings
screen -dmS swarm bash -c "
    source .venv/bin/activate
    export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
    export OMP_NUM_THREADS=8
    export MKL_NUM_THREADS=8
    export NUMEXPR_NUM_THREADS=8
    export OPENBLAS_NUM_THREADS=8
    export VECLIB_MAXIMUM_THREADS=8
    export PYTHONPATH=/opt/gensyn-rl-swarm:\$PYTHONPATH
    ./run_rl_swarm.sh
    exec bash
"

echo "$(date): GenSyn RL-Swarm started in screen session 'swarm'"
echo "To attach to session: screen -r swarm"
echo "To detach from session: CTRL+A+D"
echo "To kill session: screen -XS swarm quit"
EOF

chmod +x $GENSYN_DIR/start-swarm.sh

# Create management script
cat > $GENSYN_DIR/manage.sh << 'EOF'
#!/bin/bash

GENSYN_DIR="/opt/gensyn-rl-swarm"
LOG_DIR="/var/log/gensyn"

case "$1" in
    start)
        echo "Starting GenSyn RL-Swarm..."
        $GENSYN_DIR/start-swarm.sh
        ;;
    stop)
        echo "Stopping GenSyn RL-Swarm..."
        screen -XS swarm quit 2>/dev/null || true
        ;;
    restart)
        echo "Restarting GenSyn RL-Swarm..."
        screen -XS swarm quit 2>/dev/null || true
        sleep 3
        $GENSYN_DIR/start-swarm.sh
        ;;
    status)
        echo "=== GenSyn RL-Swarm Status ==="
        echo "Screen sessions:"
        screen -ls | grep swarm || echo "No swarm session found"
        echo ""
        echo "Processes:"
        ps aux | grep -E "(python|node)" | grep -v grep || echo "No GenSyn processes found"
        echo ""
        echo "Recent logs:"
        tail -10 $LOG_DIR/keep-alive.log 2>/dev/null || echo "No keep-alive logs found"
        ;;
    logs)
        echo "=== GenSyn RL-Swarm Logs ==="
        tail -f $LOG_DIR/keep-alive.log 2>/dev/null || echo "No keep-alive logs found"
        ;;
    monitor)
        echo "=== System Monitoring ==="
        htop
        ;;
    attach)
        echo "Attaching to GenSyn screen session..."
        screen -r swarm
        ;;
    backup)
        echo "Creating backup..."
        $GENSYN_DIR/backup.sh
        ;;
    update)
        echo "Updating GenSyn RL-Swarm..."
        cd $GENSYN_DIR
        git pull
        source .venv/bin/activate
        pip install -r requirements.txt
        cd modal-login && yarn install && cd ..
        echo "Update completed. Restarting..."
        $GENSYN_DIR/manage.sh restart
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|monitor|attach|backup|update}"
        echo ""
        echo "Commands:"
        echo "  start   - Start GenSyn RL-Swarm"
        echo "  stop    - Stop GenSyn RL-Swarm"
        echo "  restart - Restart GenSyn RL-Swarm"
        echo "  status  - Show status and recent logs"
        echo "  logs    - Follow logs in real-time"
        echo "  monitor - Open system monitor"
        echo "  attach  - Attach to screen session"
        echo "  backup  - Create backup of swarm.pem"
        echo "  update  - Update GenSyn RL-Swarm"
        exit 1
        ;;
esac
EOF

chmod +x $GENSYN_DIR/manage.sh

# Create backup script
cat > $GENSYN_DIR/backup.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/opt/backups/gensyn"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup swarm.pem if it exists
if [ -f "/opt/gensyn-rl-swarm/swarm.pem" ]; then
    cp /opt/gensyn-rl-swarm/swarm.pem $BACKUP_DIR/swarm.pem.backup.$DATE
    echo "Backup created: $BACKUP_DIR/swarm.pem.backup.$DATE"
else
    echo "No swarm.pem found to backup"
fi

# Clean old backups (keep last 7 days)
find $BACKUP_DIR -name "swarm.pem.backup.*" -mtime +7 -delete

echo "Backup completed at $(date)"
EOF

chmod +x $GENSYN_DIR/backup.sh

# Setup systemd services
print_status "Setting up systemd services..."

# Create keep-alive service
cat > /etc/systemd/system/gensyn-keepalive.service << EOF
[Unit]
Description=GenSyn Keep Alive Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=$GENSYN_DIR/keep-alive.sh
Restart=always
RestartSec=10
StandardOutput=append:$LOG_DIR/keep-alive.log
StandardError=append:$LOG_DIR/keep-alive.log

[Install]
WantedBy=multi-user.target
EOF

# Create monitoring service
cat > /etc/systemd/system/gensyn-monitor.service << EOF
[Unit]
Description=GenSyn Monitoring Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=$GENSYN_DIR/monitor.sh
Restart=always
RestartSec=30
StandardOutput=append:$LOG_DIR/monitor.log
StandardError=append:$LOG_DIR/monitor.log

[Install]
WantedBy=multi-user.target
EOF

# Enable and start services
systemctl enable gensyn-keepalive.service
systemctl enable gensyn-monitor.service
systemctl start gensyn-keepalive.service
systemctl start gensyn-monitor.service

# Setup log rotation
cat > /etc/logrotate.d/gensyn << EOF
$LOG_DIR/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        systemctl reload gensyn-keepalive.service > /dev/null 2>&1 || true
        systemctl reload gensyn-monitor.service > /dev/null 2>&1 || true
    endscript
}
EOF

# Setup firewall
print_status "Setting up firewall..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 3000/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# Setup fail2ban
print_status "Setting up fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban

# Create fail2ban configuration
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF

systemctl restart fail2ban

# Setup cron jobs
print_status "Setting up cron jobs..."

# Add backup job to root crontab
(crontab -l 2>/dev/null; echo "0 2 * * * $GENSYN_DIR/backup.sh") | crontab -

# Add system maintenance job
(crontab -l 2>/dev/null; echo "0 4 * * 0 apt-get update && apt-get upgrade -y") | crontab -

# Setup system optimization
print_status "Setting up system optimization..."

# Optimize system parameters
cat >> /etc/sysctl.conf << EOF

# GenSyn RL-Swarm optimizations
vm.swappiness=10
vm.vfs_cache_pressure=50
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.ipv4.tcp_congestion_control=bbr
net.core.default_qdisc=fq
EOF

sysctl -p

# Create swap file if needed
if [ ! -f /swapfile ]; then
    print_status "Creating swap file..."
    fallocate -l 4G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# Set proper permissions
chown -R $SWARM_USER:$SWARM_GROUP $GENSYN_DIR
chown -R $SWARM_USER:$SWARM_GROUP $LOG_DIR
chown -R $SWARM_USER:$SWARM_GROUP $BACKUP_DIR

# Create final setup script
cat > $GENSYN_DIR/final-setup.sh << 'EOF'
#!/bin/bash

echo "=== GenSyn RL-Swarm Final Setup ==="
echo ""
echo "1. Starting GenSyn RL-Swarm..."
/opt/gensyn-rl-swarm/start-swarm.sh

echo ""
echo "2. Waiting for services to start..."
sleep 10

echo ""
echo "3. Checking service status..."
systemctl status gensyn-keepalive.service --no-pager
systemctl status gensyn-monitor.service --no-pager

echo ""
echo "4. Checking screen sessions..."
screen -ls

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Management commands:"
echo "  /opt/gensyn-rl-swarm/manage.sh start    - Start GenSyn"
echo "  /opt/gensyn-rl-swarm/manage.sh stop     - Stop GenSyn"
echo "  /opt/gensyn-rl-swarm/manage.sh status   - Show status"
echo "  /opt/gensyn-rl-swarm/manage.sh logs     - View logs"
echo "  /opt/gensyn-rl-swarm/manage.sh attach   - Attach to session"
echo "  /opt/gensyn-rl-swarm/manage.sh update   - Update GenSyn"
echo ""
echo "Log files:"
echo "  /var/log/gensyn/keep-alive.log"
echo "  /var/log/gensyn/monitor.log"
echo "  /var/log/gensyn/alerts.log"
echo ""
echo "Backup location:"
echo "  /opt/backups/gensyn/"
echo ""
echo "Important: Backup your swarm.pem file when it's generated!"
echo "Location: /opt/gensyn-rl-swarm/swarm.pem"
EOF

chmod +x $GENSYN_DIR/final-setup.sh

print_header "Deployment Complete!"
print_status "GenSyn RL-Swarm has been deployed with advanced anti-suspension measures."
print_status ""
print_status "Next steps:"
print_status "1. Run: $GENSYN_DIR/final-setup.sh"
print_status "2. Complete Modal authentication setup"
print_status "3. Monitor logs: tail -f $LOG_DIR/keep-alive.log"
print_status ""
print_status "Management commands:"
print_status "  $GENSYN_DIR/manage.sh start    - Start GenSyn"
print_status "  $GENSYN_DIR/manage.sh stop     - Stop GenSyn"
print_status "  $GENSYN_DIR/manage.sh status   - Show status"
print_status "  $GENSYN_DIR/manage.sh logs     - View logs"
print_status "  $GENSYN_DIR/manage.sh attach   - Attach to session"
print_status ""
print_status "Anti-suspension features enabled:"
print_status "  ✓ Keep-alive service with random intervals"
print_status "  ✓ Resource monitoring and alerts"
print_status "  ✓ Network connectivity checks"
print_status "  ✓ Automatic restart on failure"
print_status "  ✓ System optimization for n2-standard-8"
print_status "  ✓ Firewall and security hardening"
print_status "  ✓ Automatic backups"
print_status ""
print_warning "Remember to backup your swarm.pem file when it's generated!"
print_status "Location: $GENSYN_DIR/swarm.pem" 