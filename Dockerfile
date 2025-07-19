# Use Python 3.11 slim image for better performance
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    nodejs \
    npm \
    yarn \
    && rm -rf /var/lib/apt/lists/*

# Clone the GenSyn RL-Swarm repository
RUN git clone https://github.com/gensyn-ai/rl-swarm.git .

# Install Python dependencies from the actual project
RUN pip install --no-cache-dir -r requirements.txt

# Install Node.js dependencies for modal-login
WORKDIR /app/modal-login
RUN yarn install

# Go back to root directory
WORKDIR /app

# Create necessary directories
RUN mkdir -p logs models

# Create a non-root user for security
RUN useradd -m -u 1000 gensyn && chown -R gensyn:gensyn /app
USER gensyn

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000 || exit 1

# Expose ports for GenSyn RL-Swarm
EXPOSE 3000

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
ENV NODE_ENV=production

# Start command - use the actual GenSyn RL-Swarm script
CMD ["./run_rl_swarm.sh"] 