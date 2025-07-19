# Ubuntu VPS Guide for GenSyn RL-Swarm

This guide is specifically designed for **Ubuntu VPS instances** to run the [GenSyn RL-Swarm](https://github.com/gensyn-ai/rl-swarm) project without getting suspended. Based on the comprehensive guide by [0xmoei](https://github.com/0xmoei/gensyn-ai).

## 🎯 **Ubuntu VPS Requirements**

### **Minimum Specifications**
- **OS**: Ubuntu 20.04 LTS or Ubuntu 22.04 LTS
- **CPU**: 8 vCPUs (recommended)
- **RAM**: 32 GB (minimum)
- **Storage**: 50 GB SSD
- **Network**: 1 Gbps

### **Recommended VPS Providers**
- **DigitalOcean**: Droplets with 8 vCPU, 32GB RAM
- **Linode**: Dedicated CPU instances
- **Vultr**: High Performance instances
- **AWS EC2**: t3.2xlarge or larger
- **Google Cloud**: n2-standard-8

### **GPU Support** (Optional)
- **RTX 3090/4090**: Excellent performance
- **A100**: Professional grade
- **H100**: Enterprise grade
- **CPU-only**: Works with smaller models

## 🚀 **Quick Deployment**

### **Step 1: Connect to Your Ubuntu VPS**
```bash
ssh root@your-vps-ip
```

### **Step 2: Download and Run the Deployment Script**
```bash
# Download the deployment script
wget https://raw.githubusercontent.com/your-repo/deploy-ubuntu-vps.sh

# Make it executable
chmod +x deploy-ubuntu-vps.sh

# Run the deployment (as root)
sudo ./deploy-ubuntu-vps.sh
```

### **Step 3: Access GenSyn RL-Swarm**
- **Web Interface**: `http://your-vps-ip:3000`
- **Modal Login**: Complete the authentication setup

## 🤖 **Model Selection Guide**

### **CPU-Friendly Models** (Recommended for VPS)
1. **Gensyn/Qwen2.5-0.5B-Instruct** - Best for CPU
2. **Qwen/Qwen3-0.6B** - Good CPU performance
3. **nvidia/AceInstruct-1.5B** - Balanced performance

### **GPU Models** (If you have GPU)
1. **dnotitia/Smoothie-Qwen3-1.7B** - Good GPU performance
2. **Gensyn/Qwen2.5-1.5B-Instruct** - Enhanced performance

### **Model Selection Tips**
- **Start with smaller models** (0.5B-0.6B) for CPU-only VPS
- **Use larger models** only if you have sufficient GPU
- **Monitor resource usage** and adjust accordingly

## 🔧 **Manual Ubuntu Setup** (Alternative)

If you prefer manual setup:

### **1. Update Ubuntu System**
```bash
sudo apt-get update && sudo apt-get upgrade -y
```

### **2. Install Essential Packages**
```bash
sudo apt-get install -y \
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
```

### **3. Install Python 3.11**
```bash
# Add deadsnakes PPA for Python 3.11
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt-get update
sudo apt-get install -y python3.11 python3.11-pip python3.11-venv python3.11-dev
```

### **4. Install Node.js 18**
```bash
# Add NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -
sudo apt-get install -y nodejs

# Install Yarn
sudo npm install -g yarn
```

### **5. Setup GenSyn RL-Swarm**
```bash
# Create application directory
sudo mkdir -p /opt/gensyn-rl-swarm
cd /opt/gensyn-rl-swarm

# Clone the repository
sudo git clone https://github.com/gensyn-ai/rl-swarm.git .

# Create Python virtual environment
python3 -m venv .venv

# Install Python dependencies
source .venv/bin/activate
pip install -r requirements.txt

# Install Node.js dependencies
cd modal-login
yarn install
cd ..

# Create necessary directories
mkdir -p logs models data
```

### **6. Apply Fixes from 0xmoei Guide**
```bash
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
case $- in
    *i*) ;;
    *) return;;
esac
BASHRC
fi
```

### **7. Create Anti-Suspension Scripts**
```bash
# Create keep-alive script
sudo tee /opt/gensyn-rl-swarm/keep-alive.sh > /dev/null << 'EOF'
#!/bin/bash
while true; do
    echo "$(date): GenSyn RL-Swarm is running..." >> /var/log/gensyn.log
    curl -s https://www.google.com > /dev/null 2>&1
    sleep 300
done
EOF

sudo chmod +x /opt/gensyn-rl-swarm/keep-alive.sh
```

### **8. Setup Systemd Services**
```bash
# Create keep-alive service
sudo tee /etc/systemd/system/gensyn-keepalive.service > /dev/null << 'EOF'
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
EOF

# Enable and start services
sudo systemctl enable gensyn-keepalive.service
sudo systemctl start gensyn-keepalive.service
```

### **9. Create Screen Session Script**
```bash
# Create screen session script
sudo tee /opt/gensyn-rl-swarm/start-swarm.sh > /dev/null << 'EOF'
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
EOF

sudo chmod +x /opt/gensyn-rl-swarm/start-swarm.sh
```

## 🛠️ **Management Commands**

### **Service Management**
```bash
# Start GenSyn RL-Swarm in screen session
/opt/gensyn-rl-swarm/start-swarm.sh

# Stop GenSyn RL-Swarm
screen -XS swarm quit

# Restart services
screen -XS swarm quit
systemctl restart gensyn-keepalive.service
/opt/gensyn-rl-swarm/start-swarm.sh

# Check status
screen -ls
systemctl status gensyn-keepalive.service
```

### **Using the Management Script**
```bash
# If you used the automated deployment script
/opt/gensyn-rl-swarm/manage.sh start
/opt/gensyn-rl-swarm/manage.sh stop
/opt/gensyn-rl-swarm/manage.sh restart
/opt/gensyn-rl-swarm/manage.sh status
/opt/gensyn-rl-swarm/manage.sh logs
/opt/gensyn-rl-swarm/manage.sh monitor
/opt/gensyn-rl-swarm/manage.sh attach
/opt/gensyn-rl-swarm/manage.sh backup
/opt/gensyn-rl-swarm/manage.sh update
```

### **Screen Commands**
```bash
# Attach to screen session
screen -r swarm

# Detach from screen session
# Press: CTRL + A + D

# List screen sessions
screen -ls

# Kill screen session
screen -XS swarm quit
```

## 🔒 **Security Considerations**

### **Firewall Setup**
```bash
# Install UFW (Uncomplicated Firewall)
sudo apt-get install ufw

# Allow SSH
sudo ufw allow ssh

# Allow GenSyn RL-Swarm port
sudo ufw allow 3000

# Enable firewall
sudo ufw enable
```

### **SSH Security**
```bash
# Change SSH port (optional)
sudo nano /etc/ssh/sshd_config
# Change Port 22 to Port 2222

# Restart SSH service
sudo systemctl restart sshd
```

## 📊 **Monitoring and Maintenance**

### **Resource Monitoring**
```bash
# Install monitoring tools
sudo apt-get install -y htop iotop nethogs

# Create monitoring script
sudo tee /opt/gensyn-rl-swarm/monitor.sh > /dev/null << 'EOF'
#!/bin/bash
while true; do
    echo "=== $(date) ===" >> /var/log/gensyn-monitor.log
    echo "CPU: $(top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1)%" >> /var/log/gensyn-monitor.log
    echo "Memory: $(free | grep Mem | awk '{printf("%.2f%%", $3/$2 * 100.0)}')" >> /var/log/gensyn-monitor.log
    echo "Disk: $(df / | tail -1 | awk '{print $5}')" >> /var/log/gensyn-monitor.log
    echo "Screen Sessions: $(screen -ls | grep swarm | wc -l)" >> /var/log/gensyn-monitor.log
    echo "---" >> /var/log/gensyn-monitor.log
    sleep 60
done
EOF

sudo chmod +x /opt/gensyn-rl-swarm/monitor.sh
nohup sudo /opt/gensyn-rl-swarm/monitor.sh > /dev/null 2>&1 &
```

### **Backup Strategy**
```bash
# Create backup script
sudo tee /opt/gensyn-rl-swarm/backup.sh > /dev/null << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/backups/gensyn"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR
cp /opt/gensyn-rl-swarm/swarm.pem $BACKUP_DIR/swarm.pem.backup.$DATE
echo "Backup created: $BACKUP_DIR/swarm.pem.backup.$DATE"
EOF

sudo chmod +x /opt/gensyn-rl-swarm/backup.sh

# Add to crontab for daily backups
sudo crontab -e
# Add: 0 2 * * * /opt/gensyn-rl-swarm/backup.sh
```

## 🚨 **Troubleshooting**

### **Common Issues**

1. **Service won't start**
   ```bash
   # Check screen sessions
   screen -ls
   
   # Check logs
   tail -f /var/log/gensyn.log
   ```

2. **Port 3000 not accessible**
   ```bash
   # Check if service is listening
   netstat -tlnp | grep 3000
   
   # Check firewall
   ufw status
   ```

3. **High resource usage**
   ```bash
   # Monitor resources
   htop
   
   # Check specific processes
   ps aux | grep python
   ps aux | grep node
   ```

4. **VPS getting suspended**
   ```bash
   # Check keep-alive service
   systemctl status gensyn-keepalive.service
   
   # Check logs
   tail -f /var/log/gensyn.log
   ```

5. **CPU issues with large models**
   ```bash
   # Use smaller models
   # Gensyn/Qwen2.5-0.5B-Instruct
   # Qwen/Qwen3-0.6B
   ```

6. **Screen session issues**
   ```bash
   # Kill all screen sessions
   screen -wipe
   
   # Start fresh
   /opt/gensyn-rl-swarm/start-swarm.sh
   ```

### **Performance Optimization**

1. **Swap Space** (if needed)
   ```bash
   # Create swap file
   sudo fallocate -l 4G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   
   # Make permanent
   echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
   ```

2. **System Tuning**
   ```bash
   # Optimize for performance
   echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
   echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
   sudo sysctl -p
   ```

3. **Environment Variables**
   ```bash
   # Add to your startup script
   export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
   ```

## 💰 **Cost Optimization**

### **VPS Provider Tips**
- **DigitalOcean**: Use reserved instances for discounts
- **Linode**: Consider annual billing for savings
- **Vultr**: Use high performance instances for better value
- **AWS**: Use spot instances for cost savings (but they can be terminated)

### **Resource Optimization**
- Monitor usage and downsize if possible
- Use swap space to reduce RAM requirements
- Schedule backups during low-usage hours
- Consider using preemptible instances for non-critical workloads
- Use CPU-friendly models to reduce resource requirements

## 📞 **Support and Resources**

### **Official Resources**
- **Dashboard**: https://dashboard.gensyn.ai/
- **Contract**: https://gensyn-testnet.explorer.alchemy.com/
- **Guide**: https://github.com/0xmoei/gensyn-ai
- **Original Repo**: https://github.com/gensyn-ai/rl-swarm

### **Community Support**
- **GenSyn Discord**: https://discord.gg/gensyn
- **GitHub Issues**: Check the original repository for known issues

### **Getting Help**
If you encounter issues:
1. Check the logs: `tail -f /var/log/gensyn.log`
2. Review the [0xmoei guide](https://github.com/0xmoei/gensyn-ai) for troubleshooting
3. Check the [GenSyn Discord](https://discord.gg/gensyn) for community support
4. Use the management script: `/opt/gensyn-rl-swarm/manage.sh status`

---

**Note**: This guide is specifically optimized for Ubuntu VPS instances and includes anti-suspension measures to keep your VPS running continuously. Based on the comprehensive guide by [0xmoei](https://github.com/0xmoei/gensyn-ai). 