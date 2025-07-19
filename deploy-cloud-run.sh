#!/bin/bash

# GenSyn RL Swarm Node Cloud Run Deployment Script
# Cloud Run never gets suspended and automatically scales

set -e

# Configuration
PROJECT_ID="your-project-id"  # Replace with your GCP project ID
REGION="us-central1"
SERVICE_NAME="gensyn-swarm-node"
IMAGE_NAME="gcr.io/$PROJECT_ID/gensyn-swarm-node"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Deploying GenSyn RL Swarm Node to Google Cloud Run${NC}"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install it first.${NC}"
    exit 1
fi

# Set project
echo -e "${YELLOW}📋 Setting GCP project...${NC}"
gcloud config set project $PROJECT_ID

# Enable required APIs
echo -e "${YELLOW}🔧 Enabling required APIs...${NC}"
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com

# Configure Docker to use gcloud as a credential helper
echo -e "${YELLOW}🐳 Configuring Docker authentication...${NC}"
gcloud auth configure-docker

# Build and push Docker image
echo -e "${YELLOW}🔨 Building Docker image...${NC}"
docker build -t $IMAGE_NAME .

echo -e "${YELLOW}📤 Pushing Docker image to Container Registry...${NC}"
docker push $IMAGE_NAME

# Deploy to Cloud Run
echo -e "${YELLOW}🚀 Deploying to Cloud Run...${NC}"
gcloud run deploy $SERVICE_NAME \
    --image $IMAGE_NAME \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --port 8000 \
    --memory 32Gi \
    --cpu 8 \
    --max-instances 1 \
    --min-instances 1 \
    --timeout 3600 \
    --concurrency 1 \
    --set-env-vars NODE_ID=gensyn-cloud-run-node,MAX_WORKERS=4,MEMORY_LIMIT=28GB,CPU_LIMIT=8,RAY_DISABLE_IMPORT_WARNING=1 \
    --cpu-boost \
    --no-cpu-throttling

# Get the service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)")

echo -e "${GREEN}✅ GenSyn RL Swarm Node deployed successfully to Cloud Run!${NC}"
echo -e "${GREEN}🌐 Service URL: $SERVICE_URL${NC}"
echo -e "${GREEN}🔗 Health check: $SERVICE_URL/health${NC}"
echo -e "${GREEN}📊 Status: $SERVICE_URL/status${NC}"

# Create monitoring script
cat > monitor-cloud-run.sh << EOF
#!/bin/bash

# Monitor Cloud Run service
echo "Monitoring GenSyn RL Swarm Node on Cloud Run..."
echo "Service URL: $SERVICE_URL"

while true; do
    echo "=== \$(date) ==="
    
    # Check health
    if curl -f -s "$SERVICE_URL/health" > /dev/null; then
        echo "✅ Health check: PASSED"
    else
        echo "❌ Health check: FAILED"
    fi
    
    # Get status
    STATUS=\$(curl -s "$SERVICE_URL/status" 2>/dev/null | jq -r '.ray_status' 2>/dev/null || echo "unknown")
    echo "📊 Ray Status: \$STATUS"
    
    # Get Cloud Run service info
    echo "📈 Cloud Run Info:"
    gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.conditions[0].status,status.conditions[0].message)" 2>/dev/null || echo "Unable to get service info"
    
    echo "---"
    sleep 60
done
EOF

chmod +x monitor-cloud-run.sh

# Create deployment summary
cat > cloud-run-deployment-summary.md << EOF
# GenSyn RL Swarm Node - Cloud Run Deployment

## Service Details
- **Service Name**: $SERVICE_NAME
- **Region**: $REGION
- **Project ID**: $PROJECT_ID
- **Service URL**: $SERVICE_URL

## Configuration
- **Memory**: 32GB
- **CPU**: 8 vCPUs
- **Min Instances**: 1 (prevents cold starts)
- **Max Instances**: 1 (cost control)
- **Timeout**: 3600 seconds (1 hour)
- **Concurrency**: 1

## Advantages of Cloud Run
1. **Never Suspended**: Cloud Run services never get suspended
2. **Auto-scaling**: Automatically scales based on demand
3. **Pay-per-use**: Only pay when requests are processed
4. **Managed**: No server management required
5. **High Availability**: 99.9% uptime SLA

## Cost Optimization
- **Min instances**: 1 (prevents cold starts but costs ~$0.38/hour)
- **Max instances**: 1 (prevents runaway costs)
- **CPU throttling**: Disabled for better performance
- **CPU boost**: Enabled for faster startup

## Monitoring
\`\`\`bash
# Monitor the service
./monitor-cloud-run.sh

# View logs
gcloud logs tail --service=$SERVICE_NAME --region=$REGION

# Check service status
gcloud run services describe $SERVICE_NAME --region=$REGION
\`\`\`

## API Endpoints
- **Health Check**: $SERVICE_URL/health
- **Status**: $SERVICE_URL/status
- **Training**: $SERVICE_URL/train (POST)

## Next Steps
1. Test the health endpoint: \`curl $SERVICE_URL/health\`
2. Monitor the service using the provided script
3. Configure your specific RL training parameters
4. Set up alerts for any issues

## Cost Estimate
- **Min instance running**: ~$0.38/hour
- **Monthly cost**: ~$273/month
- **Additional costs**: Network egress, storage (if used)
EOF

echo -e "${GREEN}📝 Deployment summary saved to cloud-run-deployment-summary.md${NC}"
echo -e "${GREEN}📊 Monitoring script created: monitor-cloud-run.sh${NC}"
echo -e "${YELLOW}💡 Cloud Run never gets suspended and automatically scales${NC}"
echo -e "${YELLOW}💡 The service will always be available with min-instances=1${NC}" 