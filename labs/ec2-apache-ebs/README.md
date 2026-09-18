# AWS CLI lab: EC2, Apache and EBS

This maintained lab consolidates the Linux-instance launch, Apache objectives and EBS walkthrough. Their original notes and scripts are preserved in [source history](../../docs/history/README.md). It uses AWS CLI CloudFormation commands so resource IDs and dependency-ordered cleanup belong to one named stack, instead of relying on variables left in a previous shell.

## Inputs and costs

Use Python 3.11+, AWS CLI v2, your existing AWS login, and a region that supports AL2023 and `t3.micro`. Supply a unique stack name, an explicit region and the IPv4 CIDR allowed to reach HTTP (normally your current public IP followed by `/32`). The operator needs CloudFormation, EC2/VPC, IAM and SSM permissions. Do not supply access keys in source files. Session Manager requires its local plugin.

The stack creates one VPC, public subnet, internet gateway, routing, restricted HTTP security group, SSM role/profile, one EC2 instance, an encrypted root disk and a separate encrypted 8-GiB gp3 volume in the same AZ. EC2, storage and public IPv4 can incur charges. There is no NAT gateway in this small lab. **Cleanup deletes the data volume and any data written during the exercise.**

## Launch, install Apache and attach EBS

Run from this repository's root after replacing the example CIDR with your actual address:

```sh
python labs/ec2-apache-ebs/lab.py deploy --stack ec2-storage-lab --region us-east-1 --http-cidr 203.0.113.10/32
python labs/ec2-apache-ebs/lab.py verify --stack ec2-storage-lab --region us-east-1
```

The documentation address is not a real client address. The deploy command waits for CloudFormation. User data installs/enables Apache. EBS is attached but is not formatted automatically. The verify operation waits for EC2 health and checks the volume attachment. It does not claim Apache or disk initialization succeeded.

Use the returned Website with `curl --fail <website-url>`. Open `aws ssm start-session --target <InstanceId> --region us-east-1`; wait a few minutes for the SSM agent if necessary. Inspect `sudo cloud-init status --wait`, `sudo systemctl status httpd` and `curl --fail http://localhost`. A failed bootstrap is visible in `/var/log/cloud-init-output.log`.

## Identify and use the data volume

Inside the SSM session, inspect `lsblk -o NAME,SERIAL,SIZE,FSTYPE,MOUNTPOINTS`. NVMe names are not stable; match the **DataVolumeId** output (without its hyphen in the serial). Copy the reviewed `mount-data-volume.sh` contents into a file on that instance, then run:

```sh
sudo bash mount-data-volume.sh <DataVolumeId> --format-new
sudo sh -c 'printf "lab verification\n" > /mnt/lab-data/check.txt'
cat /mnt/lab-data/check.txt
findmnt /mnt/lab-data
df -h /mnt/lab-data
```

The helper formats only an explicitly selected, unmounted, unpartitioned, blank volume and requires `--format-new`. It refuses a mounted/root/partitioned disk or a different filesystem. It adds a UUID-based fstab entry. If already mounted, inspect it; do not format again.

For an optional resize, deliberately modify only the DataVolumeId with `aws ec2 modify-volume --volume-id <id> --size 12 --region <region>`. Inspect `aws ec2 describe-volumes-modifications --volume-ids <id>` until the change is optimizing or completed; then run `sudo xfs_growfs /mnt/lab-data` on the instance and verify `df -h`. This lab uses the whole data disk, so no partition grow command is needed. A larger EBS volume cannot be shrunk in place. An out-of-band resize introduces CloudFormation drift; discard the disposable lab afterward rather than redeploying the old size over it.

## Clean up and verify

Copy out any data you need; then exit the SSM session. The explicit stack-name confirmation prevents an accidental cleanup of a mistyped target:

```sh
python labs/ec2-apache-ebs/lab.py cleanup --stack ec2-storage-lab --confirm-stack ec2-storage-lab --region us-east-1
```

Record the InstanceId and DataVolumeId before cleanup, and verify afterward that EC2 reports the instance terminated and the volume no longer exists. Check CloudFormation events if deletion fails; do not treat a failed operation as completed. No wildcard cleanup or account-wide deletion is used.

## Validation and limitations

The root validation workflow covers the template, Python command/error tests and shell syntax/lint. No AWS resources were created while developing this consolidation. Capture actual region, commit, timestamps, HTTP response, volume attachment/mount and cleanup evidence when you perform the exercise. This is a learning environment, not a production configuration or availability guarantee.

Sources: [AL2023 image selection](https://docs.aws.amazon.com/linux/al2023/ug/ec2.html), [EBS NVMe mapping](https://docs.aws.amazon.com/ebs/latest/userguide/identify-nvme-ebs-device.html), [mounting EBS](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-using-volumes.html).
