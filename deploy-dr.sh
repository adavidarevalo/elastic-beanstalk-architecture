#!/bin/bash

# Deploy Disaster Recovery Infrastructure
echo "Deploying DR Infrastructure to us-west-1..."

# 1. Deploy DR Stack to us-west-1
echo "Step 1: Deploying DR stack to us-west-1..."
sam build --template template-dr.yaml
sam deploy --template-file .aws-sam/build/template.yaml \
    --stack-name elastic-beanstalk-example-dr \
    --region us-west-1 \
    --parameter-overrides DeployFrontend=true DeployBackend=true \
    --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND CAPABILITY_NAMED_IAM \
    --resolve-s3 --no-confirm-changeset

# 2. Configure S3 Cross-Region Replication
echo "Step 2: Configuring S3 Cross-Region Replication..."
aws cloudformation deploy \
    --template-file s3-crr-template.yml \
    --stack-name s3-cross-region-replication \
    --region us-east-1 \
    --capabilities CAPABILITY_IAM

# 3. Get DR endpoints
echo "Step 3: Getting DR endpoints..."
DR_API_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name elastic-beanstalk-example-dr \
    --region us-west-1 \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayURL`].OutputValue' \
    --output text | sed 's|https://||')

DR_FRONTEND_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name elastic-beanstalk-example-dr \
    --region us-west-1 \
    --query 'Stacks[0].Outputs[?OutputKey==`FrontendURL`].OutputValue' \
    --output text | sed 's|https://||')

echo "DR API Endpoint: $DR_API_ENDPOINT"
echo "DR Frontend Endpoint: $DR_FRONTEND_ENDPOINT"

# 4. Deploy Route 53 DNS Failover
echo "Step 4: Deploying Route 53 DNS Failover..."
aws cloudformation deploy \
    --template-file route53-failover.yml \
    --stack-name route53-dns-failover \
    --region us-east-1 \
    --parameter-overrides \
        SecondaryApiEndpoint=$DR_API_ENDPOINT \
        SecondaryFrontendEndpoint=$DR_FRONTEND_ENDPOINT \
    --capabilities CAPABILITY_IAM

echo "DR Infrastructure deployment completed!"
echo "Primary Region: us-east-1"
echo "DR Region: us-west-1"
echo "DNS Failover: Configured with health checks"
echo "S3 CRR: Enabled from us-east-1 to us-west-1"