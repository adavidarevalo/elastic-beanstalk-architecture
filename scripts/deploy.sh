#!/bin/bash

set -e

echo "🚀 Starting deployment of all stacks..."

# Deploy VPC Stack
echo "📡 Deploying VPC Stack..."
sam deploy --template-file vpc-stack.yml --stack-name vpc-stack --capabilities CAPABILITY_IAM --no-confirm-changeset --no-fail-on-empty-changeset

# Get VPC Stack outputs
echo "📋 Getting VPC Stack outputs..."
VPC_ID=$(aws cloudformation describe-stacks --stack-name vpc-stack --query "Stacks[0].Outputs[?OutputKey=='VpcId'].OutputValue" --output text)
PUBLIC_SUBNET_1=$(aws cloudformation describe-stacks --stack-name vpc-stack --query "Stacks[0].Outputs[?OutputKey=='PublicSubnet1Id'].OutputValue" --output text)
PUBLIC_SUBNET_2=$(aws cloudformation describe-stacks --stack-name vpc-stack --query "Stacks[0].Outputs[?OutputKey=='PublicSubnet2Id'].OutputValue" --output text)
PRIVATE_SUBNET_1=$(aws cloudformation describe-stacks --stack-name vpc-stack --query "Stacks[0].Outputs[?OutputKey=='PrivateSubnet1Id'].OutputValue" --output text)
PRIVATE_SUBNET_2=$(aws cloudformation describe-stacks --stack-name vpc-stack --query "Stacks[0].Outputs[?OutputKey=='PrivateSubnet2Id'].OutputValue" --output text)
DATABASE_SUBNET_1=$(aws cloudformation describe-stacks --stack-name vpc-stack --query "Stacks[0].Outputs[?OutputKey=='DatabaseSubnet1Id'].OutputValue" --output text)
DATABASE_SUBNET_2=$(aws cloudformation describe-stacks --stack-name vpc-stack --query "Stacks[0].Outputs[?OutputKey=='DatabaseSubnet2Id'].OutputValue" --output text)

# Deploy Backend Stack
echo "🏗️ Deploying Backend Stack..."
sam deploy --template-file backend-template.yaml --stack-name backend-stack --capabilities CAPABILITY_IAM --no-confirm-changeset --no-fail-on-empty-changeset --parameter-overrides \
  VpcId=$VPC_ID \
  PublicSubnet1Id=$PUBLIC_SUBNET_1 \
  PublicSubnet2Id=$PUBLIC_SUBNET_2 \
  PrivateSubnet1Id=$PRIVATE_SUBNET_1 \
  PrivateSubnet2Id=$PRIVATE_SUBNET_2 \
  DatabaseSubnet1Id=$DATABASE_SUBNET_1 \
  DatabaseSubnet2Id=$DATABASE_SUBNET_2

# Get application URL
echo "🌐 Getting application URL..."
APP_URL=$(aws cloudformation describe-stacks --stack-name backend-stack --query "Stacks[0].Outputs[?OutputKey=='ElasticBeanstalkURL'].OutputValue" --output text)

echo "✅ Deployment completed successfully!"
echo "🔗 Application URL: $APP_URL"