# Launching-a-Linux-Instance-Using-the-AWS-CLI

When we purchase a laptop, we have a physical device in front of us that we can log in to after setting up our account. However, EC2 instances are in the cloud, and we are expected to connect to our instances to manage hardware, maintain software, deploy application packages, and complete other tasks.

## Objectives
1. Launch an EC2 instance using the AWS CLI
2. Create key pairs and network resources using the AWS CLI
3. Verify the instance in the AWS Console

## Create a Key Pair
We'll use the AWS CLI to create a key pair easily, without having to navigate through UI screens on the AWS Console.
```Bash
# Execute this command to get the key created and uploaded to AWS

aws ec2 create-key-pair --key-name my-lab04-keypair --key-type rsa --key-format pem --query "KeyMaterial" --output text > my-lab04-keypair.pem
echo "Key pair was successfully created"
```
Execute this command to create a new my-lab04-keypair key, or adjust the command to create a key using the name of your choice. The public key is automatically uploaded to AWS, while the private key is written to a file (my-lab04-keypair.pem) in the local directory. To check this, issue ls -latr at the command prompt—you should see the file containing our newly created key pair in the list.

## Creating a VPC
A virtual private cloud is a private network that will help segregate and construct a portion of the AWS Cloud for our purposes. All resources that we create must be present in a VPC.
```bash
echo "Creating a VPC"

VPC_ID=`aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text`
echo "Successfully created a VPC: $VPC_ID"
```
## Creating a Subnet
A subnet is a logical grouping of IP addresses. We usually assign a set of IP addresses in that subnet to resources like instances.
```bash
echo "Creating a subnet"

SUBNET_ID=`aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --query Subnet.SubnetId --output text` 
echo "Successfully created a subnet: $SUBNET_ID"
```
## Creating an Internet Gateway
An internet gateway permits our resources in the VPC to talk to external resources on the internet. With the following command, we'll create an internet gateway and attach it to our VPC:
```bash
echo "Configuring an internet gateway"

INTERNET_GATEWAY_ID=`aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text`

echo "Successfully created an internet gateway: $INTERNET_GATEWAY_ID"
echo "Attaching this internet gateway to our VPC"

aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $INTERNET_GATEWAY_ID
```
## Creating a Route
We have created the VPC, subnet, and internet gateway; the next thing on our list is a route. A route enables network traffic flow between our instances in the subnet to the internet via an internet gateway. Multiple routes make up a route table. Each subnet is associated with a set of routes.
```bash
echo "Configuring route table"
ROUTE_TABLE_ID=`aws ec2 create-route-table --vpc-id $VPC_ID --query RouteTable.RouteTableId --output text`
echo "Successfully created route table: $ROUTE_TABLE_ID"
echo "Adding a route"
aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $INTERNET_GATEWAY_ID
echo "Successfully added a route"
echo "Associate the route table with the subnet"
aws ec2 associate-route-table --subnet-id $SUBNET_ID --route-table-id $ROUTE_TABLE_ID
echo "Successfully associated the route table with the subnet"
```
## Create a Security Group
In this step, we'll create a new security group and add a couple of rules so the incoming and outgoing traffic is controlled as per a policy.
```bash
echo "Creating a new security group"

SECURITY_GROUP_NAME=$username-security-group
SECURITY_GROUP=`aws ec2 create-security-group --vpc-id $VPC_ID  --group-name $SECURITY_GROUP_NAME --description "My $SECURITY_GROUP_NAME security group" --region us-east-1 --output text`
echo "New security group $SECURITY_GROUP was created successfully"
```
## Add Inbound Rules
A security group allows or disallows all network traffic to and from the instance. It consists of a set of rules that dictate what ports are open and what protocols (e.g., SSH, TCP, Telnet) are permitted.

In our current use case, we do not expect our instance to communicate with any other resources (like a database or other EC2 instances). As such, we can allow outbound traffic to remain curtailed by opting not to add any outbound rules to the security group.

However, we do want to connect to the instance via port 22 over SSH protocol. That means we must create a new inbound rule that permits SSH traffic on port 22. This rule will be added to the security group, which will then let us communicate with the instance by SSHing into it.
```bash
echo "Adding a TCP rule for SSH connectivity for remote access"
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP --protocol tcp  --port 22 --cidr 0.0.0.0/0 --region us-east-1
echo "The SSH connectivity for remote access is enabled"
```
## Creating an Instance
In the previous steps, we completed all the prerequisites required for creating an EC2 instance. Now it is time to create our instance.
```bash
echo "Creating a new EC2 instance..."
KEY_NAME=my-lab04-keypair

echo "Key is $KEY_NAME"

INSTANCE_ID=`aws ec2 run-instances --image-id ami-09d3b3274b6c5d4aa --instance-type t2.micro --key-name $KEY_NAME --security-group-ids $SECURITY_GROUP --subnet-id $SUBNET_ID --associate-public-ip-address --count 1 --query 'Instances[0].InstanceId' --output text --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=my-ec2-instance}]'`

echo "Instance with ID $INSTANCE_ID was created successfully"
```
