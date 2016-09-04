#!/bin/bash

#set -x

KEY_NAME="simple_key"
SEC_GRP="simple-sg"
AMI_ID="ami-d85e75b0"
BUCKET_NAME="simple-bucket-007"

aws s3 mb s3://$BUCKET_NAME > /dev/null 2>&1
aws s3 cp ~/Desktop/aws/add_hdd.json s3://$BUCKET_NAME/ --acl public-read > /dev/null 2>&1
aws s3 ls s3://$BUCKET_NAME/add_hdd.json > /dev/null 2>&1
if [ $? -eq 0 ]
then
        echo "Create Bucket and add file SUCCESS"
else
        echo "ERROR create Bucket and add file"
fi

################################################################
SEC_GRP_ID=`aws ec2 create-security-group --group-name $SEC_GRP --description "security group for test in EC2" --output text` 
#>> ~/Desktop/aws/source.txt 
aws ec2 authorize-security-group-ingress --group-name $SEC_GRP --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 describe-security-groups --group-name $SEC_GRP > /dev/null 2>&1
if [ $? -eq 0 ]
then
	echo "Create SECURITY GROUP SUCCESS"
else
	echo "ERROR create SECURITY_GROUP"
fi
#################################################################
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > ~/Desktop/aws/keys/$KEY_NAME.pem
chmod 400 ~/Desktop/aws/keys/$KEY_NAME.pem
aws ec2 describe-key-pairs --key-name $KEY_NAME > /dev/null 2>&1
if [ $? -eq 0 ]
then
        echo "Create KEY PAIR SUCCESS"
else
        echo "ERROR create KEY PAIR"
fi
#######################################################
INST_ID=`aws ec2 run-instances --image-id $AMI_ID --count 1 --instance-type t1.micro --key-name $KEY_NAME --security-groups $SEC_GRP --block-device-mappings https://s3.amazonaws.com/$BUCKET_NAME/add_hdd.json --query 'Instances[0].InstanceId'`

#file://~/Desktop/aws/add_hdd.json --query 'Instances[0].InstanceId'`

sleep 200

aws ec2 describe-instances --instance-ids $INST_ID --filters Name=instance-state-code,Values=16 --query Reservations[].Instances[].State.Name > /dev/null 2>&1
if [ $? -eq 0 ]
then
        echo "Create INSTANCE SUCCESS"
else
        echo "ERROR create INSTANCE"
fi
#######################################################
PUB_IP=`aws ec2 allocate-address --query 'PublicIp'`
aws ec2 associate-address --instance-id $INST_ID --public-ip $PUB_IP

sleep 30

CHECK_IP=`aws ec2 describe-instances --instance-id $INST_ID --query 'Reservations[0].Instances[0].PublicIpAddress'`
if [ $CHECK_IP = $PUB_IP ]
then
        echo "Allocate PUB_IP SUCESS"
else
        echo "ERROR allocate PUB_IP"
fi
