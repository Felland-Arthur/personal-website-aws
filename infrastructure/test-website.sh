#!/bin/bash

# Get the CloudFront domain from CloudFormation output
CLOUDFRONT_DOMAIN=$(aws cloudformation describe-stacks \
  --stack-name felland-portfolio-website \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDomain`].OutputValue' \
  --output text)

if [ -z "$CLOUDFRONT_DOMAIN" ]; then
    echo "ERROR: Could not retrieve CloudFront domain. Is the stack deployed?"
    exit 1
fi

echo "Testing website at: https://$CLOUDFRONT_DOMAIN"
echo ""

# Test HTTP response
echo "1. Testing HTTP response:"
curl -I -s https://$CLOUDFRONT_DOMAIN | head -n 5

echo ""

# Test content loading
echo "2. Testing content loading:"
curl -s https://$CLOUDFRONT_DOMAIN | grep -o '<title>.*</title>'

echo ""

# Test CSS file
echo "3. Testing CSS file:"
CSS_RESPONSE=$(curl -I -s https://$CLOUDFRONT_DOMAIN/css/style.css | head -n 1)
echo "CSS: $CSS_RESPONSE"

# Test image file
echo "4. Testing image file:"
IMG_RESPONSE=$(curl -I -s https://$CLOUDFRONT_DOMAIN/images/profile-placeholder.png | head -n 1)
echo "Image: $IMG_RESPONSE"

echo ""
echo "✅ Testing complete! If you see '200 OK' responses, your website is working!"
echo "🌐 Website URL: https://$CLOUDFRONT_DOMAIN"