#!/bin/bash

# Go to project root
cd "$(git rev-parse --show-toplevel)"

ECR_REGISTRY="376907302485.dkr.ecr.ap-southeast-1.amazonaws.com/teamates"

# Ensure Docker is logged in to ECR
aws ecr get-login-password --region ap-southeast-1 --profile dev | \
docker login --username AWS --password-stdin 376907302485.dkr.ecr.ap-southeast-1.amazonaws.com


for SERVICE in order-service order-processing-service; do
  JAR_PATH="$SERVICE/target/*.jar"
  IMAGE="$ECR_REGISTRY/$SERVICE"

  echo "🔨 Building image for $SERVICE..."

  docker buildx build \
    --platform=linux/amd64 \
    --load \
    -f .docker/Dockerfile \
    --build-arg JAR_FILE=$JAR_PATH \
    -t $IMAGE:latest .


  echo "🚀 Pushing $IMAGE:latest..."
  docker push $IMAGE:latest

  echo "✅ Done with $SERVICE"
done
