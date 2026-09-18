# Attaching an EBS Volume to an Instance

AWS provides storage in various forms, including Elastic Block Store (EBS) and Instance Store.

EBS volumes are durable and can survive instance crashes or terminations, whereas Instance Store volumes are ephemeral, meaning they exist only until the instance stops running. EBS provides block-level storage for storing data.

The usual pattern is to provision an EBS disk and attach it to an instance. Data gets stored on the EBS disk, which is mounted to the instance as a filesystem. When the instance is terminated for whatever reason, the EBS volume survives. We can attach this EBS volume to another instance should we need it.

In this lab, we will create an EBS volume and attach it to an instance. Note that we will not be formatting the disk or mounting the formatted disk on the instance in this lab.

# Objectives

1. Create an EBS volume using the AWS CLI
2. Attach an EBS volume to an instance
3. Modify and delete an EBS volume

### Create an EBS volume using the AWS CLI
The first of our scripts handles the prerequisites, creating a VPC, security group, rules, keys, and so on.
```bash
source ./1_create_resources.sh
```
Once the resources have been created, let's create an instance by executing the below script:
```bash
source ./2_create_instance.sh 
```
### Creating a Volume Using the AWS CLI

In the CLI, we use the create-volume command on the ec2 service to create a volume. We provide a few parameters, such as the size of the disk and availability zone. We can also provide the volume type.
However, we need to make sure we create the volume in the same availability zone as our instance. We can do so by executing the describe-subnets command:
```bash
AVAILABILITY_ZONE=`aws ec2 describe-subnets --subnet-id $SUBNET_ID --query 'Subnets[].AvailabilityZone' --output text`

echo The availability zone of the instance is: $AVAILABILITY_ZONE
```
The following command creates a volume of 10 GB in the US East region:
```bash
aws ec2 create-volume --size 10 --availability-zone  $AVAILABILITY_ZONE --tag-specification 'ResourceType=volume,Tags=[{Key=Name,Value='"$username"'-volume}]'

VOLUME_ID=`aws ec2 describe-volumes  --query "Volumes[0].VolumeId" --filters "Name=tag:Name,Values="$username"-volume" --output text`

echo "Volume $VOLUME_ID was created successfully"
```
### Fetching Volume IDs
We can also issue the describe-volumes command to verify whether the volume was created:
```bash
VOLUME_ID=`aws ec2 describe-volumes --query 'Volumes[*].VolumeId' --output text --filters 'Name=tag:Name,Values='"$username-volume"''`

echo Volume is: $VOLUME_ID
```
### Create a general-purpose volume (type gp3) with 20 GB memory

```Bash
aws ec2 create-volume --volume-type gp3 --size 20 --availability-zone us-east-1a --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value='"$username-gp3-volume"'}]'
```
### Attaching a Volume to an Instance
Let's use the following command to attach our volume to the instance:

```bash
echo "My volume ID is $VOLUME_ID"
echo "My instance ID is $INSTANCE_ID"

aws ec2 attach-volume --volume-id $VOLUME_ID --instance-id $INSTANCE_ID --device /dev/sdf
```
```bash
aws ec2 describe-volumes --query 'Volumes[*].VolumeId' --output text
```
### Modifying a Volume
First, we need to fetch the volume ID using the describe-volumes command (note that we are choosing the first of the volumes from the list):

```bash
VOLUME_ID=`aws ec2 describe-volumes  --query "Volumes[0].VolumeId" --filters "Name=tag:Name,Values="$username"-volume" --output text`

echo "Volume ID is  $VOLUME_ID"
```
If we want to know the current size of the disk, we can run the following command:
```bash
CURRENT_VOLUME_SIZE=`aws ec2 describe-volumes --volume-id $VOLUME_ID --filters "Name=tag:Name,Values="$username"-volume" --query 'Volumes[0].Size' --output text`

echo "The current size of the volume is $CURRENT_VOLUME_SIZE GB"
```
Now that we have the volume ID and size, let's upsize the disk to 25 GB:
```bash
aws ec2 modify-volume --volume-id $VOLUME_ID --size 25
```
