export KEY_FILE=quartical.pem
export KEY_NAME=quartical-key
export REGION=af-south-1
export INSTANCE_TYPE=t3.micro

export VPC=$(aws ec2 create-vpc --cidr-block 172.16.0.0/16 --query Vpc.VpcId --output text)
aws ec2 create-tags --resources $VPC --tags "Key=Name,Value=quartical-test"
export SUBNET=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 172.16.1.0/24 --query Subnet.SubnetId --output text)
export IGW=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)
aws ec2 attach-internet-gateway --vpc-id $VPC --internet-gateway-id $IGW --output text
export ROUTE_TABLE=$(aws ec2 create-route-table --vpc-id $VPC --query RouteTable.RouteTableId --output text)
aws ec2 create-route --route-table-id $ROUTE_TABLE --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW --output text
export RTBA=$(aws ec2 associate-route-table --subnet-id $SUBNET --route-table-id $ROUTE_TABLE --query "AssociationId" --output text)
export SECGRP=$(aws ec2 create-security-group --group-name test --vpc-id $VPC --description test --output text)
export SECGRPRULE=$(aws ec2 authorize-security-group-ingress --group-id $SECGRP --protocol tcp --port 22 --cidr 0.0.0.0/0 --output text)

aws ec2 create-key-pair \
        --key-name $KEY_NAME \
        --key-type ed25519 \
        --key-format pem \
        --query "KeyMaterial" \
        --output text > $KEY_FILE
chmod og-rwx $KEY_FILE

export AMI=$(aws ec2 describe-images \
        --region $REGION \
        --filters "Name=root-device-type,Values=[ebs]" \
        "Name=architecture,Values=x86_64" \
        "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04*" \
        --query "Images[*].[ImageId,CreationDate]" \
        --output text | sort -k2 -r | head -n1 | cut -f1)
