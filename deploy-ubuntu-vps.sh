#!/bin/bash

# GenSyn RL-Swarm Ubuntu VPS Deployment Script
# Based on: https://github.com/0xmoei/gensyn-ai
# For Ubuntu 20.04/22.04 VPS instances

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Deploying GenSyn RL-Swarm on Ubuntu VPS${NC}"
echo -e "${YELLOW}📋 Based on: https://github.com/0xmoei/gensyn-ai${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run as root (use sudo)${NC}"
    exit 1
fi

# Update system
echo -e "${YELLOW}📦 Updating Ubuntu system...${NC}"
apt-get update && apt-get upgrade -y

# Install essential packages
echo -e "${YELLOW}🔧 Installing essential packages...${NC}"
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
    python3-venv

# Install Python 3.11
echo -e "${YELLOW}🐍 Installing Python 3.11...${NC}"
add-apt-repository ppa:deadsnakes/ppa -y
apt-get update
apt-get install -y python3.11 python3.11-pip python3.11-venv python3.11-dev

# Install Node.js 18
echo -e "${YELLOW}📦 Installing Node.js 18...${NC}"
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install Yarn
echo -e "${YELLOW}🧶 Installing Yarn...${NC}"
npm install -g yarn

# Install Docker (optional, for containerized deployment)
echo -e "${YELLOW}🐳 Installing Docker...${NC}"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
echo -e "${YELLOW}🐙 Installing Docker Compose...${NC}"
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create application directory
echo -e "${YELLOW}📁 Setting up application directory...${NC}"
mkdir -p /opt/gensyn-rl-swarm
cd /opt/gensyn-rl-swarm

# Clone GenSyn RL-Swarm repository
echo -e "${YELLOW}📥 Cloning GenSyn RL-Swarm repository...${NC}"
git clone https://github.com/gensyn-ai/rl-swarm.git .

# Create Python virtual environment
echo -e "${YELLOW}🐍 Creating Python virtual environment...${NC}"
python3 -m venv .venv

# Install Python dependencies
echo -e "${YELLOW}🐍 Installing Python dependencies...${NC}"
source .venv/bin/activate
pip install -r requirements.txt

# Install Node.js dependencies for modal-login
echo -e "${YELLOW}📦 Installing Node.js dependencies...${NC}"
cd modal-login
yarn install
cd ..

# Create necessary directories
mkdir -p logs models data

# Fix common issues from 0xmoei guide
echo -e "${YELLOW}🔧 Applying fixes from 0xmoei guide...${NC}"

# Fix 1: CPU Configuration - Change bf16 to false and reduce max_steps
if [ -f "hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml" ]; then
    sed -i 's/bf16: true/bf16: false/' hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml
    sed -i 's/max_steps: [0-9]*/max_steps: 5/' hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml
fi

# Fix 2: Daemon timeout fix
DAEMON_FILE=$(python3 -c "import hivemind.p2p.p2p_daemon as m; print(m.__file__)" 2>/dev/null || echo "")
if [ -n "$DAEMON_FILE" ] && [ -f "$DAEMON_FILE" ]; then
    sed -i 's/startup_timeout: float = 15/startup_timeout: float = 120/' "$DAEMON_FILE"
fi

# Fix 3: PS1 unbound variable fix
if [ ! -f ~/.bashrc ]; then
    cat > ~/.bashrc << 'BASHRC'
# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac
BASHRC
fi

# Create keep-alive script to prevent suspension
echo -e "${YELLOW}🔄 Creating keep-alive script...${NC}"
cat > /opt/gensyn-rl-swarm/keep-alive.sh << 'KEEPALIVE'
#!/bin/bash
while true; do
    echo "$(date): GenSyn RL-Swarm is running..." >> /var/log/gensyn.log
    # Send a small amount of network traffic to keep the VPS active
    curl -s https://www.google.com > /dev/null 2>&1
    sleep 300  # 5 minutes
done
KEEPALIVE

chmod +x /opt/gensyn-rl-swarm/keep-alive.sh

# Create systemd service for keep-alive
echo -e "${YELLOW}⚙️ Creating systemd service...${NC}"
cat > /etc/systemd/system/gensyn-keepalive.service << 'SERVICE'
[Unit]
Description=GenSyn Keep Alive Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/opt/gensyn-rl-swarm/keep-alive.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE

# Create GenSyn RL-Swarm startup script with proper environment
cat > /opt/gensyn-rl-swarm/run_rl_swarm.sh << 'RLSWARM'
#!/bin/bash
cd /opt/gensyn-rl-swarm

# Activate virtual environment
source .venv/bin/activate

# Set environment variables
export PYTHONPATH=/opt/gensyn-rl-swarm
export NODE_ENV=production
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0

# Start the GenSyn RL-Swarm application
./run_rl_swarm.sh
RLSWARM

chmod +x /opt/gensyn-rl-swarm/run_rl_swarm.sh

# Create screen session script
cat > /opt/gensyn-rl-swarm/start-swarm.sh << 'SCREEN'
#!/bin/bash
cd /opt/gensyn-rl-swarm

# Kill existing screen session if exists
screen -XS swarm quit 2>/dev/null || true

# Start new screen session
screen -dmS swarm bash -c "source .venv/bin/activate && export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0 && ./run_rl_swarm.sh; exec bash"

echo "GenSyn RL-Swarm started in screen session 'swarm'"
echo "To attach to session: screen -r swarm"
echo "To detach from session: CTRL+A+D"
echo "To kill session: screen -XS swarm quit"
SCREEN

chmod +x /opt/gensyn-rl-swarm/start-swarm.sh

# Enable and start keep-alive service
echo -e "${YELLOW}🚀 Enabling and starting services...${NC}"
systemctl enable gensyn-keepalive.service
systemctl start gensyn-keepalive.service

# Create monitoring script
echo -e "${YELLOW}📊 Creating monitoring script...${NC}"
cat > /opt/gensyn-rl-swarm/monitor.sh << 'MONITOR'
#!/bin/bash
while true; do
    echo "=== $(date) ===" >> /var/log/gensyn-monitor.log
    echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%" >> /var/log/gensyn-monitor.log
    echo "Memory Usage: $(free | grep Mem | awk '{printf("%.2f%%", $3/$2 * 100.0)}')" >> /var/log/gensyn-monitor.log
    echo "Disk Usage: $(df / | tail -1 | awk '{print $5}')" >> /var/log/gensyn-monitor.log
    echo "Network: $(netstat -i | grep eth0 | awk '{print $3, $7}')" >> /var/log/gensyn-monitor.log
    echo "Screen Sessions: $(screen -ls | grep swarm | wc -l)" >> /var/log/gensyn-monitor.log
    echo "---" >> /var/log/gensyn-monitor.log
    sleep 60
done
MONITOR

chmod +x /opt/gensyn-rl-swarm/monitor.sh
nohup /opt/gensyn-rl-swarm/monitor.sh > /dev/null 2>&1 &

# Get VPS IP address
VPS_IP=$(curl -s ifconfig.me)

echo -e "${GREEN}✅ GenSyn RL-Swarm deployed successfully on Ubuntu VPS!${NC}"
echo -e "${GREEN}🌐 VPS IP: $VPS_IP${NC}"
echo -e "${GREEN}🔗 GenSyn RL-Swarm: http://$VPS_IP:3000${NC}"

# Create management script
cat > /opt/gensyn-rl-swarm/manage.sh << 'MANAGE'
#!/bin/bash

case "$1" in
    start)
        /opt/gensyn-rl-swarm/start-swarm.sh
        systemctl start gensyn-keepalive.service
        echo "GenSyn RL-Swarm services started"
        ;;
    stop)
        screen -XS swarm quit 2>/dev/null || true
        systemctl stop gensyn-keepalive.service
        echo "GenSyn RL-Swarm services stopped"
        ;;
    restart)
        screen -XS swarm quit 2>/dev/null || true
        systemctl restart gensyn-keepalive.service
        /opt/gensyn-rl-swarm/start-swarm.sh
        echo "GenSyn RL-Swarm services restarted"
        ;;
    status)
        echo "=== Screen Sessions ==="
        screen -ls
        echo "=== Keep-alive Service ==="
        systemctl status gensyn-keepalive.service --no-pager
        ;;
    logs)
        tail -f /var/log/gensyn.log
        ;;
    monitor)
        tail -f /var/log/gensyn-monitor.log
        ;;
    attach)
        screen -r swarm
        ;;
    backup)
        cp /opt/gensyn-rl-swarm/swarm.pem /opt/gensyn-rl-swarm/swarm.pem.backup.$(date +%Y%m%d_%H%M%S)
        echo "Backup created: swarm.pem.backup.$(date +%Y%m%d_%H%M%S)"
        ;;
    update)
        cd /opt/gensyn-rl-swarm
        git pull
        source .venv/bin/activate
        pip install -r requirements.txt
        cd modal-login && yarn install && cd ..
        echo "GenSyn RL-Swarm updated"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|monitor|attach|backup|update}"
        echo ""
        echo "Commands:"
        echo "  start   - Start GenSyn RL-Swarm in screen session"
        echo "  stop    - Stop GenSyn RL-Swarm and keep-alive service"
        echo "  restart - Restart all services"
        echo "  status  - Show status of services"
        echo "  logs    - View GenSyn logs"
        echo "  monitor - View monitoring logs"
        echo "  attach  - Attach to screen session"
        echo "  backup  - Backup swarm.pem file"
        echo "  update  - Update GenSyn RL-Swarm repository"
        exit 1
        ;;
esac
MANAGE

chmod +x /opt/gensyn-rl-swarm/manage.sh

# Create deployment summary
cat > /opt/gensyn-rl-swarm/deployment-summary.md << EOF
# GenSyn RL-Swarm Ubuntu VPS Deployment

## VPS Details
- **IP Address**: $VPS_IP
- **OS**: Ubuntu $(lsb_release -rs)
- **GenSyn RL-Swarm**: http://$VPS_IP:3000
- **Based on**: https://github.com/0xmoei/gensyn-ai

## Hardware Requirements
- **CPU**: 8 vCPUs (recommended)
- **RAM**: 32 GB (minimum)
- **Storage**: 50 GB SSD
- **GPU**: Optional (RTX 3090/4090, A100, H100 for better performance)

## Supported Models
- Gensyn/Qwen2.5-0.5B-Instruct (CPU-friendly)
- Qwen/Qwen3-0.6B (CPU-friendly)
- nvidia/AceInstruct-1.5B
- dnotitia/Smoothie-Qwen3-1.7B
- Gensyn/Qwen2.5-1.5B-Instruct

## Management Commands
\`\`\`bash
# Start GenSyn RL-Swarm
/opt/gensyn-rl-swarm/manage.sh start

# Stop GenSyn RL-Swarm
/opt/gensyn-rl-swarm/manage.sh stop

# Restart services
/opt/gensyn-rl-swarm/manage.sh restart

# Check status
/opt/gensyn-rl-swarm/manage.sh status

# View logs
/opt/gensyn-rl-swarm/manage.sh logs

# Monitor resources
/opt/gensyn-rl-swarm/manage.sh monitor

# Attach to screen session
/opt/gensyn-rl-swarm/manage.sh attach

# Backup swarm.pem
/opt/gensyn-rl-swarm/manage.sh backup

# Update GenSyn RL-Swarm
/opt/gensyn-rl-swarm/manage.sh update
\`\`\`

## Screen Commands
- **Minimize**: \`CTRL + A + D\`
- **Return**: \`screen -r swarm\`
- **Stop and Kill**: \`screen -XS swarm quit\`

## Anti-Suspension Features
- Keep-alive script runs every 5 minutes
- Systemd service starts on boot
- Network activity maintains connection
- Resource monitoring included

## Next Steps
1. Access http://$VPS_IP:3000
2. Complete the modal login setup
3. Choose your model (start with smaller models for CPU)
4. Monitor the training progress

## Troubleshooting
- Check logs: \`tail -f /var/log/gensyn.log\`
- Check system resources: \`htop\`
- Restart services if needed: \`/opt/gensyn-rl-swarm/manage.sh restart\`
- For CPU issues: Use smaller models like Qwen2.5-0.5B

## Backup and Recovery
- Backup \`swarm.pem\` file to keep your animal name
- Use \`/opt/gensyn-rl-swarm/manage.sh backup\` for automatic backup
- Restore by copying \`swarm.pem\` back to the directory

## Official Resources
- **Dashboard**: https://dashboard.gensyn.ai/
- **Contract**: https://gensyn-testnet.explorer.alchemy.com/
- **Guide**: https://github.com/0xmoei/gensyn-ai
EOF

echo -e "${GREEN}📝 Deployment summary saved to /opt/gensyn-rl-swarm/deployment-summary.md${NC}"
echo -e "${GREEN}🛠️ Management script created: /opt/gensyn-rl-swarm/manage.sh${NC}"
echo -e "${YELLOW}💡 To prevent suspension, the VPS runs a keep-alive script every 5 minutes${NC}"
echo -e "${YELLOW}💡 Monitor your VPS regularly to ensure it stays active${NC}"
echo -e "${GREEN}🎯 GenSyn RL-Swarm will be available at http://$VPS_IP:3000${NC}"
echo -e "${GREEN}📚 Based on the comprehensive guide: https://github.com/0xmoei/gensyn-ai${NC}" 