# Elastic Beanstalk Example - Full Stack Web Application

This project contains a complete full-stack web application infrastructure deployed using AWS SAM (Serverless Application Model) with nested CloudFormation stacks.

## Architecture Overview

The application consists of three main components deployed as nested stacks:

### 1. VPC Stack (`vpc-stack.yml`)
- **VPC**: 10.0.0.0/16 CIDR with DNS support
- **Public Subnets**: 2 subnets across AZs for load balancers
- **Private Subnets**: 2 subnets across AZs for application servers
- **Database Subnets**: 2 isolated subnets for RDS
- **NAT Gateways**: High availability internet access for private subnets
- **Route Tables**: Proper routing for public, private, and database tiers

### 2. Backend Stack (`backend-template.yml`)
- **Elastic Beanstalk**: Tomcat 9 application environment
- **API Gateway**: HTTP API with custom domain (api.davidarevalo.info)
- **Security Groups**: Layered security for ALB, web servers, and database
- **IAM Roles**: Least privilege access for EC2 instances
- **RDS Subnet Group**: Multi-AZ database deployment ready
- **Custom Domain**: SSL certificate integration with Route 53

### 3. Frontend Stack (`frontend-template.yml`)
- **S3 Bucket**: Static website hosting (frontend.davidarevalo.info)
- **CloudFront**: Global CDN with custom domain and SSL
- **Origin Access Control**: Secure S3 access via CloudFront
- **Route 53**: DNS management for custom domain
- **Security**: Encrypted storage and secure content delivery

## Project Structure

```
elastic-beanstalk-example/
├── template.yaml              # Main SAM template with nested stacks
├── vpc-stack.yml             # VPC and networking infrastructure
├── backend-template.yml      # Elastic Beanstalk and API Gateway
├── frontend-template.yml     # S3, CloudFront, and static hosting
├── samconfig.toml           # SAM CLI configuration
├── bucket-policy.json       # S3 bucket policy for CloudFront
└── .amazonq/rules/          # Amazon Q development guidelines
```

## Prerequisites

- AWS CLI configured with appropriate permissions
- SAM CLI installed
- Docker (for local testing)
- Valid SSL certificate in ACM (us-east-1)
- Route 53 hosted zone configured

## Deployment

### Deploy Complete Infrastructure

```bash
# Build and deploy all stacks
sam build
sam deploy --parameter-overrides DeployFrontend=true DeployBackend=true --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND CAPABILITY_NAMED_IAM
```

### Deploy Individual Components

```bash
# Deploy only VPC and Backend
sam deploy --parameter-overrides DeployBackend=true --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND CAPABILITY_NAMED_IAM

# Deploy only VPC and Frontend
sam deploy --parameter-overrides DeployFrontend=true --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND CAPABILITY_NAMED_IAM
```

## Configuration

### Custom Domains
- **API**: api.davidarevalo.info
- **Frontend**: frontend.davidarevalo.info
- **SSL Certificate**: ACM certificate required in us-east-1
- **Route 53**: Hosted zone Z0663610FALSUBU5IALA

### Security Features
- S3 bucket with public access blocked
- CloudFront Origin Access Control (OAC)
- Security groups with least privilege access
- Encrypted S3 storage (AES256)
- TLS 1.2 minimum for CloudFront

## Disaster Recovery and DNS Failover

The application includes disaster recovery deployment in us-west-1 with Route 53 DNS failover:

### Deploy DR Stack
```bash
# Deploy to us-west-1
sam build --template template-dr.yaml
sam deploy --template-file .aws-sam/build/template.yaml --stack-name elastic-beanstalk-example-dr --region us-west-1 --parameter-overrides DeployFrontend=true DeployBackend=true --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND CAPABILITY_NAMED_IAM --resolve-s3 --no-confirm-changeset
```

### Configure DNS Failover
```bash
# Get secondary endpoints from DR stack outputs
./deploy-failover.sh <secondary-api-endpoint> <secondary-frontend-endpoint>
```

The failover configuration includes:
- Health checks for primary endpoints (us-east-1)
- Automatic failover to secondary endpoints (us-west-1)
- 30-second health check intervals with 3 failure threshold

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
```

## Monitoring and Logging

- **CloudWatch**: Automatic logging for all services
- **Enhanced Health Reporting**: Enabled for Elastic Beanstalk
- **CloudFront Logging**: Available for frontend performance monitoring
- **API Gateway Logging**: HTTP API request/response logging

## Outputs

After deployment, the stack provides:
- **VPC ID**: For additional resource deployment
- **Elastic Beanstalk URL**: Direct application access
- **API Gateway URL**: RESTful API endpoint
- **Custom Domain URLs**: Production-ready endpoints
- **CloudFront Distribution**: CDN details for frontend

## Cleanup

To delete the application and all its resources:

```bash
sam delete --stack-name elastic-beanstalk-example
```

This will delete all nested stacks (VPC, Backend, Frontend) and their resources.

## Cost Optimization

- **NAT Gateways**: Consider single NAT for development
- **CloudFront**: PriceClass_100 for cost optimization
- **Elastic Beanstalk**: t2.micro instances for development
- **RDS**: Multi-AZ disabled by default (can be enabled)

## Security Best Practices

- All S3 buckets have public access blocked
- Security groups follow least privilege principle
- IAM roles use AWS managed policies
- SSL/TLS encryption enforced throughout
- VPC provides network isolation

## Resources

- [AWS SAM Developer Guide](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html)
- [Elastic Beanstalk Documentation](https://docs.aws.amazon.com/elasticbeanstalk/)
- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)