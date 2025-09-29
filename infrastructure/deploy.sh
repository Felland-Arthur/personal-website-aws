#!/bin/bash

# Variables
STACK_NAME="felland-portfolio-website"
EXISTING_S3_BUCKET="felland-ak"
REGION="us-east-1"

echo "Deployment Parameters:"
echo "S3 Bucket: $EXISTING_S3_BUCKET"
echo "Region: $REGION"
echo ""

# Validate that the S3 bucket exists
echo "Checking if S3 bucket exists..."
aws s3 ls s3://$EXISTING_S3_BUCKET > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "ERROR: S3 bucket '$EXISTING_S3_BUCKET' does not exist or you don't have access to it"
    echo "Please check the bucket name and permissions"
    exit 1
fi

echo "S3 bucket validation successful!"
echo ""

# Create the CloudFormation stack
echo "Creating CloudFormation stack..."
aws cloudformation create-stack \
  --stack-name $STACK_NAME \
  --template-body file://website-infrastructure-no-domain.yaml \
  --parameters \
      ParameterKey=ExistingS3Bucket,ParameterValue=$EXISTING_S3_BUCKET \
  --region $REGION

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create CloudFormation stack"
    exit 1
fi

# Wait for stack creation to complete
echo "Waiting for stack creation to complete (this may take 15-20 minutes)..."
aws cloudformation wait stack-create-complete \
  --stack-name $STACK_NAME \
  --region $REGION

# Check if stack creation was successful
if [ $? -eq 0 ]; then
    echo "✅ Stack creation completed successfully!"
    echo ""
    
    # Get stack outputs
    echo "📊 Stack outputs:"
    aws cloudformation describe-stacks \
      --stack-name $STACK_NAME \
      --region $REGION \
      --query 'Stacks[0].Outputs' \
      --output table
    
    echo ""
    
    # Get the CloudFront domain name
    CLOUDFRONT_DOMAIN=$(aws cloudformation describe-stacks \
      --stack-name $STACK_NAME \
      --region $REGION \
      --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDomain`].OutputValue' \
      --output text)
    
    # Create CloudFront cache invalidation
    CLOUDFRONT_DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
      --stack-name $STACK_NAME \
      --region $REGION \
      --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDistributionId`].OutputValue' \
      --output text)
    
    echo "🔄 Creating CloudFront cache invalidation..."
    aws cloudfront create-invalidation \
      --distribution-id $CLOUDFRONT_DISTRIBUTION_ID \
      --paths "/*" \
      --region $REGION
    
    echo ""
    echo "🎉 Deployment complete!"
    echo "🌐 Your website is available at: https://$CLOUDFRONT_DOMAIN"
    echo ""
    echo "Next steps:"
    echo "1. Wait a few minutes for the CloudFront distribution to deploy globally"
    echo "2. Test your website: https://$CLOUDFRONT_DOMAIN"
    echo "3. You can add a custom domain later by updating the stack"
    
else
    echo "❌ Stack creation failed. Check the CloudFormation console for details."
    echo ""
    # Show stack events for debugging
    echo "Recent stack events:"
    aws cloudformation describe-stack-events \
      --stack-name $STACK_NAME \
      --region $REGION \
      --query 'StackEvents[0:10]' \
      --output table
fi