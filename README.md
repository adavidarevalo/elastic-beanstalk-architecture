# Elastic Beanstalk Example - Full Stack Web Application with Disaster Recovery

This project contains a complete full-stack web application infrastructure deployed using AWS SAM (Serverless Application Model) with nested CloudFormation stacks, featuring multi-region disaster recovery with automatic failover.

## Architecture Overview

The application consists of a primary deployment in **us-east-1** and a disaster recovery deployment in **us-west-1**, with automatic DNS failover and data replication.

### Primary Region (us-east-1)

#### 1. VPC Stack (`vpc-stack.yml`)
- **VPC**: 10.0.0.0/16 CIDR with DNS support
- **Public Subnets**: 2 subnets across AZs for load balancers
- **Private Subnets**: 2 subnets across AZs for application servers
- **Database Subnets**: 2 isolated subnets for RDS
- **NAT Gateways**: High availability internet access for private subnets
- **Route Tables**: Proper routing for public, private, and database tiers

#### 2. Backend Stack (`backend-template.yml`)
- **Elastic Beanstalk**: Tomcat 9 application environment
- **API Gateway**: HTTP API with custom domain (api.davidarevalo.info)
- **Security Groups**: Layered security for ALB, web servers, and database
- **IAM Roles**: Least privilege access for EC2 instances
- **RDS Subnet Group**: Multi-AZ database deployment ready
- **Custom Domain**: SSL certificate integration with Route 53

#### 3. Frontend Stack (`frontend-template.yml`)
- **S3 Bucket**: Static website hosting (frontend.davidarevalo.info)
- **CloudFront**: Global CDN with custom domain and SSL
- **Origin Access Control**: Secure S3 access via CloudFront
- **Route 53**: DNS management for custom domain
- **S3 Cross-Region Replication**: Automatic data replication to DR region

### Disaster Recovery Region (us-west-1)

#### 1. DR Infrastructure (`template-dr.yaml`)
- **Complete VPC**: Identical networking setup in us-west-1
- **Backend DR**: Elastic Beanstalk + API Gateway without custom domain
- **Frontend DR**: S3 + CloudFront for static content serving
- **Automated Deployment**: Single command deployment

#### 2. Cross-Region Replication (`s3-crr-template.yml`)
- **S3 CRR**: Automatic replication from primary to DR bucket
- **IAM Role**: Dedicated role for replication permissions
- **Storage Class**: STANDARD_IA for cost optimization

#### 3. DNS Failover (`route53-failover.yml`)
- **Health Checks**: Monitor primary endpoints (30s intervals)
- **Automatic Failover**: Route traffic to DR on primary failure
- **Primary/Secondary Records**: Weighted routing with health evaluation

## Project Structure

```
elastic-beanstalk-example/
├── template.yaml              # Main SAM template (us-east-1)
├── template-dr.yaml           # DR SAM template (us-west-1)
├── vpc-stack.yml             # VPC and networking infrastructure
├── backend-template.yml      # Primary backend stack
├── backend-template-dr.yml   # DR backend stack
├── frontend-template.yml     # Primary frontend stack
├── frontend-template-dr.yml  # DR frontend stack
├── s3-crr-template.yml       # S3 Cross-Region Replication
├── route53-failover.yml      # DNS failover configuration
├── deploy-dr.sh              # Complete DR deployment script
├── samconfig.toml           # SAM CLI configuration
└── .amazonq/rules/          # Amazon Q development guidelines
```

## Prerequisites

- AWS CLI configured with appropriate permissions
- SAM CLI installed
- Docker (for local testing)
- Valid SSL certificate in ACM (us-east-1)
- Route 53 hosted zone configured
- Cross-region permissions for S3 replication

## Deployment

### Deploy Primary Infrastructure (us-east-1)

```bash
# Build and deploy primary stack
sam build
sam deploy --parameter-overrides DeployFrontend=true DeployBackend=true --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND CAPABILITY_NAMED_IAM
```

### Deploy Complete Disaster Recovery

```bash
# Deploy DR infrastructure, S3 CRR, and DNS failover
./deploy-dr.sh
```

This automated script will:
1. Deploy complete DR infrastructure to us-west-1
2. Configure S3 Cross-Region Replication
3. Set up Route 53 DNS failover with health checks
4. Automatically configure all endpoints

### Manual DR Deployment Steps

```bash
# 1. Deploy DR stack to us-west-1
sam build --template template-dr.yaml
sam deploy --template-file .aws-sam/build/template.yaml --stack-name elastic-beanstalk-example-dr --region us-west-1 --parameter-overrides DeployFrontend=true DeployBackend=true --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND CAPABILITY_NAMED_IAM --resolve-s3 --no-confirm-changeset

# 2. Configure S3 Cross-Region Replication
aws cloudformation deploy --template-file s3-crr-template.yml --stack-name s3-cross-region-replication --region us-east-1 --capabilities CAPABILITY_IAM

# 3. Set up DNS failover (replace with actual DR endpoints)
aws cloudformation deploy --template-file route53-failover.yml --stack-name route53-dns-failover --region us-east-1 --parameter-overrides SecondaryApiEndpoint=<dr-api-endpoint> SecondaryFrontendEndpoint=<dr-frontend-endpoint> --capabilities CAPABILITY_IAM
```

## Configuration

### Custom Domains
- **Primary API**: api.davidarevalo.info
- **Primary Frontend**: frontend.davidarevalo.info
- **SSL Certificate**: ACM certificate required in us-east-1
- **Route 53**: Hosted zone Z0663610FALSUBU5IALA

### Disaster Recovery
- **DR Region**: us-west-1
- **S3 CRR**: frontend.davidarevalo.info → frontend-dr.davidarevalo.info
- **Health Check Interval**: 30 seconds
- **Failure Threshold**: 3 consecutive failures
- **Failover TTL**: 60 seconds

### Security Features
- S3 buckets with public access blocked
- CloudFront Origin Access Control (OAC)
- Security groups with least privilege access
- Encrypted S3 storage (AES256)
- TLS 1.2 minimum for CloudFront
- Cross-region IAM roles for replication

## Disaster Recovery Features

### Automatic Failover
- **Health Monitoring**: Continuous monitoring of primary endpoints
- **DNS Failover**: Automatic traffic routing to DR region
- **Data Replication**: Real-time S3 content replication
- **RTO**: ~5 minutes (DNS propagation + health check)
- **RPO**: Near real-time (S3 CRR)

### Manual Failover Testing
```bash
# Test health check failure simulation
aws route53 get-health-check --health-check-id <health-check-id>

# Monitor replication status
aws s3api head-object --bucket frontend-dr.davidarevalo.info --key index.html --region us-west-1
```

## Local Development

### Build Application
```bash
sam build
```

### Local API Testing
```bash
sam local start-api
curl http://localhost:3000/
```

### Validate Templates
```bash
sam validate
sam validate --template template-dr.yaml
```

## Monitoring and Logging

- **CloudWatch**: Automatic logging for all services
- **Enhanced Health Reporting**: Enabled for Elastic Beanstalk
- **Route 53 Health Checks**: Primary endpoint monitoring
- **S3 CRR Metrics**: Replication monitoring and alerts
- **CloudFront Logging**: Performance monitoring across regions

## Outputs

### Primary Stack Outputs
- **VPC ID**: For additional resource deployment
- **Elastic Beanstalk URL**: Direct application access
- **API Gateway URL**: RESTful API endpoint
- **Custom Domain URLs**: Production-ready endpoints
- **CloudFront Distribution**: CDN details

### DR Stack Outputs
- **DR API Gateway URL**: Secondary API endpoint
- **DR CloudFront URL**: Secondary frontend endpoint
- **Health Check IDs**: For monitoring configuration

## Cleanup

### Delete DR Infrastructure
```bash
# Delete DR stack
aws cloudformation delete-stack --stack-name elastic-beanstalk-example-dr --region us-west-1

# Delete DNS failover
aws cloudformation delete-stack --stack-name route53-dns-failover --region us-east-1

# Delete S3 CRR
aws cloudformation delete-stack --stack-name s3-cross-region-replication --region us-east-1
```

### Delete Primary Infrastructure
```bash
sam delete --stack-name elastic-beanstalk-example
```

## Cost Optimization

- **NAT Gateways**: Consider single NAT for development
- **CloudFront**: PriceClass_100 for cost optimization
- **Elastic Beanstalk**: t2.micro instances for development
- **S3 CRR**: STANDARD_IA storage class for DR bucket
- **Route 53**: Health checks incur minimal cost
- **Cross-Region Data Transfer**: Monitor replication costs

## Security Best Practices

- All S3 buckets have public access blocked
- Security groups follow least privilege principle
- IAM roles use AWS managed policies
- SSL/TLS encryption enforced throughout
- VPC provides network isolation
- Cross-region replication uses dedicated IAM roles
- Health checks use HTTPS endpoints

## Disaster Recovery Testing

### Quarterly DR Tests
1. **Failover Test**: Simulate primary region failure
2. **Data Integrity**: Verify S3 CRR completeness
3. **Performance Test**: Measure DR region response times
4. **Failback Test**: Return traffic to primary region

### Monitoring Alerts
- S3 replication failure alerts
- Health check failure notifications
- DNS failover event logging
- Cross-region latency monitoring

## Resources

- [AWS SAM Developer Guide](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html)
- [Elastic Beanstalk Documentation](https://docs.aws.amazon.com/elasticbeanstalk/)
- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [S3 Cross-Region Replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html)
- [Route 53 Health Checks](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover.html)