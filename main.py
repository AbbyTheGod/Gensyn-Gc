import os
import logging
import asyncio
import signal
import sys
from typing import Dict, Any
import ray
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from pydantic import BaseModel
import psutil
import time

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(title="GenSyn RL Swarm Node", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint for container orchestration"""
    return {
        "status": "healthy",
        "timestamp": time.time(),
        "memory_usage": psutil.virtual_memory().percent,
        "cpu_usage": psutil.cpu_percent()
    }

# GenSyn RL Swarm Node Configuration
class SwarmConfig(BaseModel):
    node_id: str
    max_workers: int = 4
    memory_limit: str = "8GB"
    cpu_limit: int = 8

class SwarmNode:
    def __init__(self, config: SwarmConfig):
        self.config = config
        self.ray_cluster = None
        self.is_running = False
        
    async def initialize(self):
        """Initialize Ray cluster for distributed RL"""
        try:
            # Initialize Ray with cluster configuration
            ray.init(
                num_cpus=self.config.cpu_limit,
                object_store_memory=int(self.config.memory_limit.replace("GB", "")) * 1024 * 1024 * 1024,
                ignore_reinit_error=True,
                log_to_driver=False
            )
            logger.info(f"Ray cluster initialized with {self.config.cpu_limit} CPUs")
            self.is_running = True
        except Exception as e:
            logger.error(f"Failed to initialize Ray cluster: {e}")
            raise
    
    async def start_training(self, task_config: Dict[str, Any]):
        """Start RL training task"""
        if not self.is_running:
            raise RuntimeError("Swarm node not initialized")
        
        try:
            # Here you would implement your specific RL training logic
            # This is a placeholder for GenSyn RL training
            logger.info(f"Starting RL training task: {task_config}")
            
            # Simulate training process
            await asyncio.sleep(5)
            
            return {
                "status": "training_started",
                "task_id": task_config.get("task_id", "unknown"),
                "node_id": self.config.node_id
            }
        except Exception as e:
            logger.error(f"Training failed: {e}")
            raise
    
    async def shutdown(self):
        """Shutdown Ray cluster"""
        if self.is_running:
            ray.shutdown()
            self.is_running = False
            logger.info("Ray cluster shutdown")

# Global swarm node instance
swarm_node = None

@app.on_event("startup")
async def startup_event():
    """Initialize swarm node on startup"""
    global swarm_node
    
    # Get configuration from environment variables
    config = SwarmConfig(
        node_id=os.getenv("NODE_ID", "gensyn-node-1"),
        max_workers=int(os.getenv("MAX_WORKERS", "4")),
        memory_limit=os.getenv("MEMORY_LIMIT", "8GB"),
        cpu_limit=int(os.getenv("CPU_LIMIT", "8"))
    )
    
    swarm_node = SwarmNode(config)
    await swarm_node.initialize()
    logger.info(f"GenSyn RL Swarm Node {config.node_id} started")

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    global swarm_node
    if swarm_node:
        await swarm_node.shutdown()
    logger.info("GenSyn RL Swarm Node shutdown")

# API endpoints
@app.post("/train")
async def start_training(task_config: Dict[str, Any]):
    """Start a new RL training task"""
    if not swarm_node:
        raise HTTPException(status_code=503, detail="Swarm node not initialized")
    
    try:
        result = await swarm_node.start_training(task_config)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/status")
async def get_status():
    """Get swarm node status"""
    if not swarm_node:
        raise HTTPException(status_code=503, detail="Swarm node not initialized")
    
    return {
        "node_id": swarm_node.config.node_id,
        "is_running": swarm_node.is_running,
        "memory_usage": psutil.virtual_memory().percent,
        "cpu_usage": psutil.cpu_percent(),
        "ray_status": "running" if swarm_node.is_running else "stopped"
    }

# Signal handlers for graceful shutdown
def signal_handler(signum, frame):
    logger.info(f"Received signal {signum}, shutting down gracefully...")
    sys.exit(0)

signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

if __name__ == "__main__":
    # Run with uvicorn for production
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=False,
        workers=1,
        log_level="info"
    )
