#!/bin/bash

# Destroy All Infrastructure
echo "Destroying all infrastructure..."

# 1. Delete Route 53 DNS Failover
echo "Step 1: Deleting Route 53 DNS Failover..."
aws cloudformation delete-stack --stack-name route53-dns-failover --region us-east-1

# 2. Delete S3 Cross-Region Replication
echo "Step 2: Deleting S3 Cross-Region Replication..."
aws cloudformation delete-stack --stack-name s3-cross-region-replication --region us-east-1

# 3. Delete DR Stack (us-west-1)
echo "Step 3: Deleting DR stack from us-west-1..."
aws cloudformation delete-stack --stack-name elastic-beanstalk-example-dr --region us-west-1

# 4. Delete Primary Stack (us-east-1)
echo "Step 4: Deleting primary stack from us-east-1..."
sam delete --stack-name elastic-beanstalk-example --no-prompts

echo "All infrastructure destroyed!"