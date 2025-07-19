# GenSyn RL-Swarm Node - Containerized Deployment

This project provides a containerized deployment solution for the [GenSyn RL-Swarm](https://github.com/gensyn-ai/rl-swarm) project - a fully open source framework for creating RL training swarms over the internet.

## 🎯 About GenSyn RL-Swarm

- **Repository**: https://github.com/gensyn-ai/rl-swarm
- **Description**: Fully open source framework for creating RL training swarms over the internet
- **Stars**: 1.2k+ | **Forks**: 464+
- **Features**: Distributed RL training, web interface, modal login, real-time monitoring

## 🚀 Quick Start

### Option 1: Google Cloud Run (Recommended - Never Suspended)

Cloud Run is a serverless platform that never gets suspended and automatically scales:

```bash
# 1. Update the PROJECT_ID in deploy-cloud-run.sh
# 2. Make the script executable
chmod +x deploy-cloud-run.sh

# 3. Deploy to Cloud Run
./deploy-cloud-run.sh
```

**Advantages:**
- ✅ Never gets suspended
- ✅ Auto-scaling
- ✅ Pay-per-use pricing
- ✅ Managed service
- ✅ High availability (99.9% SLA)

### Option 2: Google Compute Engine (With Anti-Suspension)

For more control and custom configurations:

```bash
# 1. Update the PROJECT_ID in deploy-gcp.sh
# 2. Make the script executable
chmod +x deploy-gcp.sh

# 3. Deploy to Compute Engine
./deploy-gcp.sh
```

**Anti-Suspension Features:**
- Keep-alive script running every 5 minutes
- Systemd service that starts on boot
- Network activity to maintain connection
- Resource monitoring

### Option 3: Local Docker Development

For local testing and development:

```bash
# Build and run with Docker Compose
docker-compose up --build

# Or build and run manually
docker build -t gensyn-rl-swarm .
docker run -p 3000:3000 --name gensyn-rl-swarm gensyn-rl-swarm
```

## 📋 Prerequisites

### For Google Cloud Deployment:
1. **Google Cloud SDK** installed and configured
2. **Docker** installed locally
3. **GCP Project** with billing enabled
4. **Required APIs** enabled (scripts handle this automatically)

### For Local Development:
1. **Docker** and **Docker Compose**
2. **Python 3.11+** (for local development)
3. **Node.js 18+** and **Yarn** (for modal-login)

## 🏗️ Architecture

The GenSyn RL-Swarm consists of:

- **Web Interface**: React-based frontend with modal login
- **Backend API**: Python-based RL training coordination
- **Distributed Training**: Multi-node RL model training
- **Real-time Monitoring**: Training progress and performance tracking

### Key Components

- **modal-login**: Authentication system
- **RL Training Engine**: Distributed reinforcement learning
- **Web Dashboard**: Real-time monitoring interface
- **Swarm Coordination**: Multi-node training management

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NODE_ID` | `gensyn-rl-swarm-local` | Unique identifier for the node |
| `MAX_WORKERS` | `4` | Maximum number of training workers |
| `MEMORY_LIMIT` | `8GB` | Memory limit for training |
| `CPU_LIMIT` | `8` | CPU limit for training |
| `NODE_ENV` | `production` | Node.js environment |

### Resource Requirements

- **CPU**: 8 vCPUs
- **Memory**: 32 GB RAM
- **Storage**: 50 GB SSD
- **Network**: Standard tier

## 💰 Cost Optimization

### Cloud Run (Recommended)
- **Min instances**: 1 (prevents cold starts)
- **Max instances**: 1 (cost control)
- **Estimated cost**: ~$273/month

### Compute Engine
- **Instance type**: n2-standard-8
- **Estimated cost**: ~$273/month
- **Additional**: Keep-alive scripts prevent suspension

### Cost-Saving Tips
1. Use **preemptible instances** for non-critical workloads
2. **Schedule instances** to run only during training hours
3. **Monitor usage** and adjust resources accordingly
4. Consider **spot instances** for cost savings

## 🛠️ Development

### Local Development Setup

```bash
# Clone the repository
git clone https://github.com/gensyn-ai/rl-swarm.git
cd rl-swarm

# Install Python dependencies
pip install -r requirements.txt

# Install Node.js dependencies
cd modal-login
yarn install
cd ..

# Run the application
python main.py  # or the appropriate startup command
```

### Understanding GenSyn RL-Swarm

The GenSyn RL-Swarm project provides:

1. **Distributed RL Training**: Train RL models across multiple nodes
2. **Web Interface**: User-friendly dashboard for monitoring
3. **Modal Login**: Secure authentication system
4. **Real-time Updates**: Live training progress tracking
5. **Swarm Coordination**: Multi-node training management

## 📊 Monitoring

### Built-in Monitoring

The GenSyn RL-Swarm includes:
- **Web Dashboard**: Real-time training progress
- **Performance Metrics**: CPU, memory, training metrics
- **Logging**: Comprehensive training logs
- **Health Checks**: Application status monitoring

### External Monitoring

```bash
# Monitor Cloud Run service
./monitor-cloud-run.sh

# View logs
gcloud logs tail --service=gensyn-rl-swarm --region=us-central1

# Check web interface
curl http://your-service-url:3000
```

## 🔒 Security

### Container Security
- **Non-root user** execution
- **Minimal base image** (Python slim)
- **Health checks** for container orchestration
- **Resource limits** to prevent abuse

### Network Security
- **Firewall rules** for specific ports
- **HTTPS endpoints** (Cloud Run)
- **Authentication** via modal-login

## 🚨 Troubleshooting

### Common Issues

1. **Container fails to start**
   - Check Docker logs: `docker logs gensyn-rl-swarm`
   - Verify resource limits in docker-compose.yml

2. **Web interface not accessible**
   - Check if port 3000 is accessible
   - Verify modal-login dependencies are installed
   - Review Node.js setup

3. **RL training fails**
   - Check Python dependencies
   - Verify GPU/CPU configuration
   - Review training parameters

4. **Instance getting suspended (Compute Engine)**
   - Verify keep-alive script is running
   - Check systemd service status
   - Monitor network activity

### Debug Commands

```bash
# Check container status
docker ps -a

# View container logs
docker logs gensyn-rl-swarm

# Check system resources
htop
df -h
free -h

# Test web interface
curl http://localhost:3000
```

## 📚 Additional Resources

- [GenSyn RL-Swarm GitHub](https://github.com/gensyn-ai/rl-swarm)
- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Docker Documentation](https://docs.docker.com/)
- [Node.js Documentation](https://nodejs.org/docs/)

## 🤝 Contributing

1. Fork the [GenSyn RL-Swarm repository](https://github.com/gensyn-ai/rl-swarm)
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This deployment solution is licensed under the MIT License. The GenSyn RL-Swarm project has its own license - see the [original repository](https://github.com/gensyn-ai/rl-swarm) for details.

---

**Note**: This deployment ensures your GenSyn RL-Swarm node runs continuously without suspension. Cloud Run is recommended for the most reliable operation, while Compute Engine provides more control but requires additional configuration to prevent suspension. 