echo "Script to create an instance."

echo "*** MAKE SURE THE 1_create_resources.sh SCRIPT WAS RUN BEFORE EXECUTING THIS SCRIPT ***"

KEY_NAME=$username-key

echo "Creating a brand new EC2 instance "

INSTANCE_ID=`aws ec2 run-instances \
--image-id ami-09d3b3274b6c5d4aa \
--instance-type t2.micro \
--key-name $KEY_NAME \
--security-group-ids $SECURITY_GROUP \
--subnet-id $SUBNET_ID \
--associate-public-ip-address \
--count 1 \
--query 'Instances[0].InstanceId' \
--output text \
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='"$username-instance"'}]'`

echo "Instance with ID $INSTANCE_ID was created successfully"

echo "Your instance will be available shortly"$ 
