# GenSyn RL-Swarm Node - Containerized Deployment

This project provides a containerized deployment solution for the [GenSyn RL-Swarm](https://github.com/gensyn-ai/rl-swarm) project - a fully open source framework for creating RL training swarms over the internet.

## 🎯 **Use These Guides Instead**

### **Primary Guide (Recommended)**
- **[0xmoei's Comprehensive Guide](https://github.com/0xmoei/gensyn-ai)** - 136 stars, detailed Ubuntu VPS setup
- **Best for**: Ubuntu VPS deployment with anti-suspension features

### **Alternative Guide**
- **[zunxbt's Testnet Guide](https://github.com/zunxbt/gensyn-testnet)** - Alternative deployment methods
- **Best for**: Different deployment approaches and configurations

## 🚀 **Quick Start (Using 0xmoei Guide)**

### **Step 1: Follow the Official Guide**
```bash
# Clone the 0xmoei guide repository
git clone https://github.com/0xmoei/gensyn-ai.git
cd gensyn-ai

# Follow the README.md instructions
```

### **Step 2: Ubuntu VPS Setup**
Based on the [0xmoei guide](https://github.com/0xmoei/gensyn-ai):

```bash
# SSH into your Ubuntu VPS
ssh root@your-vps-ip

# Clone the official GenSyn RL-Swarm repository
git clone https://github.com/gensyn-ai/rl-swarm.git
cd rl-swarm

# Install dependencies
pip install -r requirements.txt

# Install Node.js dependencies
cd modal-login
yarn install
cd ..

# Run the swarm
./run_rl_swarm.sh
```

## 🤖 **Model Selection (from 0xmoei Guide)**

### **CPU-Friendly Models** (Recommended for VPS)
1. **Gensyn/Qwen2.5-0.5B-Instruct** - Best for CPU
2. **Qwen/Qwen3-0.6B** - Good CPU performance
3. **nvidia/AceInstruct-1.5B** - Balanced performance

### **GPU Models** (If you have GPU)
1. **dnotitia/Smoothie-Qwen3-1.7B** - Good GPU performance
2. **Gensyn/Qwen2.5-1.5B-Instruct** - Enhanced performance

## 🔧 **Hardware Requirements**

### **Minimum Specifications**
- **CPU**: 8 vCPUs (recommended)
- **RAM**: 32 GB (minimum)
- **Storage**: 50 GB SSD
- **Network**: 1 Gbps

### **GPU Support** (Optional)
- **RTX 3090/4090**: Excellent performance
- **A100**: Professional grade
- **H100**: Enterprise grade
- **CPU-only**: Works with smaller models

## 🛠️ **Management Commands**

### **Screen Commands** (from 0xmoei guide)
```bash
# Start in screen session
screen -dmS swarm bash -c "./run_rl_swarm.sh; exec bash"

# Attach to screen session
screen -r swarm

# Detach from screen session
# Press: CTRL + A + D

# Kill screen session
screen -XS swarm quit
```

### **Update Node** (from 0xmoei guide)
```bash
# Stop node
screen -XS swarm quit

# Update repository
cd rl-swarm
git pull

# Re-run node
./run_rl_swarm.sh
```

## 🚨 **Troubleshooting** (from 0xmoei guide)

### **CPU Configuration Fix**
```bash
cd rl-swarm
nano hivemind_exp/configs/mac/grpo-qwen-2.5-0.5b-deepseek-r1.yaml

# Change bf16 value to false
# Reduce max_steps to 5
```

### **Alternative Run Command**
```bash
python3 -m venv .venv
source .venv/bin/activate
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0 && ./run_rl_swarm.sh
```

### **Daemon Timeout Fix**
```bash
# Find daemon config file
nano $(python3 -c "import hivemind.p2p.p2p_daemon as m; print(m.__file__)")

# Change startup_timeout: float = 15 to startup_timeout: float = 120
```

## 📊 **Monitoring**

### **Official Dashboards**
- **Dashboard**: https://dashboard.gensyn.ai/
- **Contract**: https://gensyn-testnet.explorer.alchemy.com/

### **Node Health**
- Monitor your node's peer ID, rewards, wins, etc.
- Check the dashboard for real-time status

## 💰 **Cost Optimization**

### **VPS Provider Tips**
- **DigitalOcean**: Use reserved instances for discounts
- **Linode**: Consider annual billing for savings
- **Vultr**: Use high performance instances for better value
- **AWS**: Use spot instances for cost savings (but they can be terminated)

### **Resource Optimization**
- Use CPU-friendly models (0.5B-0.6B) for VPS
- Monitor usage and downsize if possible
- Schedule backups during low-usage hours

## 📞 **Support and Resources**

### **Official Resources**
- **Original Repo**: https://github.com/gensyn-ai/rl-swarm
- **0xmoei Guide**: https://github.com/0xmoei/gensyn-ai
- **zunxbt Guide**: https://github.com/zunxbt/gensyn-testnet

### **Community Support**
- **GenSyn Discord**: https://discord.gg/gensyn
- **GitHub Issues**: Check the original repository for known issues

## 🎯 **Why Use These Guides?**

1. **Proven Methods**: Both guides have been tested by the community
2. **Regular Updates**: Guides are maintained and updated
3. **Community Support**: Active community behind these guides
4. **No Custom Scripts**: Use the official, tested methods
5. **Better Support**: Get help from the guide authors and community

## 📋 **Quick Reference**

### **Essential Commands**
```bash
# Clone and setup
git clone https://github.com/gensyn-ai/rl-swarm.git
cd rl-swarm
pip install -r requirements.txt
cd modal-login && yarn install && cd ..

# Run in screen
screen -dmS swarm bash -c "./run_rl_swarm.sh; exec bash"

# Monitor
screen -r swarm

# Update
screen -XS swarm quit
git pull
./run_rl_swarm.sh
```

### **Important Files**
- **swarm.pem**: Your node identity (backup this!)
- **logs/**: Training logs
- **models/**: Trained models

---

**Note**: This repository serves as a reference to the established guides. For the most up-to-date and tested methods, always refer to the [0xmoei guide](https://github.com/0xmoei/gensyn-ai) and [zunxbt guide](https://github.com/zunxbt/gensyn-testnet). 