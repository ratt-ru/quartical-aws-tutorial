rm -f mapping.json
rm -f quartical.pem
aws ec2 delete-key-pair --key-name $KEY_NAME
aws ec2 delete-security-group --group-id $SECGRP
aws ec2 disassociate-route-table --association-id $RTBA
aws ec2 delete-route-table --route-table-id $ROUTE_TABLE
aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC
aws ec2 delete-internet-gateway --internet-gateway-id $IGW
aws ec2 delete-subnet --subnet-id $SUBNET
aws ec2 delete-vpc --vpc-id $VPC
