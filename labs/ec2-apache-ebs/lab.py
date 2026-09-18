"""Explicit AWS CLI operations. Importing this module never contacts AWS."""
import argparse
import ipaddress
import json
from pathlib import Path
import re
import subprocess
import sys

TEMPLATE = Path(__file__).with_name("template.yaml")

def parse_args(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["deploy", "verify", "cleanup"])
    parser.add_argument("--stack", required=True)
    parser.add_argument("--region", required=True)
    parser.add_argument("--http-cidr", help="Required on deploy; your public IPv4 CIDR")
    parser.add_argument("--confirm-stack", help="Required on cleanup; must exactly match --stack")
    args = parser.parse_args(argv)
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9-]{0,127}", args.stack):
        parser.error("Use a valid CloudFormation stack name, not an ARN or wildcard")
    if not re.fullmatch(r"[a-z]{2}(?:-[a-z]+)+-[0-9]", args.region):
        parser.error("Supply an AWS region name")
    if args.action == "deploy":
        try:
            network = ipaddress.ip_network(args.http_cidr, strict=True)
            if network.version != 4:
                raise ValueError("IPv4 required")
        except (ValueError, TypeError):
            parser.error("--http-cidr must be an explicit valid IPv4 CIDR, e.g. your public IP/32")
    if args.action == "cleanup" and args.confirm_stack != args.stack:
        parser.error("--confirm-stack must exactly match --stack; cleanup deletes the lab and its data volume")
    return args

def aws(args, *command):
    result = subprocess.run(["aws", *command, "--region", args.region, "--no-cli-pager"],
                            check=True, capture_output=True, text=True)
    return result.stdout

def outputs(args):
    result = json.loads(aws(args, "cloudformation", "describe-stacks", "--stack-name", args.stack, "--output", "json"))
    stack = result["Stacks"][0]
    if stack["StackStatus"] not in {"CREATE_COMPLETE", "UPDATE_COMPLETE"}:
        raise RuntimeError("Stack is not successfully deployed: " + stack["StackStatus"])
    return {item["OutputKey"]: item["OutputValue"] for item in stack["Outputs"]}

def run(args):
    if args.action == "deploy":
        aws(args, "cloudformation", "deploy", "--stack-name", args.stack, "--template-file", str(TEMPLATE),
            "--parameter-overrides", "HttpCidr=" + args.http_cidr, "--capabilities", "CAPABILITY_IAM",
            "--no-fail-on-empty-changeset", "--tags", "Project=ec2-apache-ebs-lab")
        print(json.dumps(outputs(args), indent=2))
    elif args.action == "verify":
        values = outputs(args)
        aws(args, "ec2", "wait", "instance-status-ok", "--instance-ids", values["InstanceId"])
        volumes = json.loads(aws(args, "ec2", "describe-volumes", "--volume-ids", values["DataVolumeId"], "--output", "json"))
        attachments = volumes["Volumes"][0]["Attachments"]
        if not any(a["InstanceId"] == values["InstanceId"] and a["State"] == "attached" for a in attachments):
            raise RuntimeError("Data volume is not attached to the expected instance")
        print(json.dumps(values, indent=2))
        print("EC2 checks and volume attachment passed. Verify HTTP, cloud-init and the mounted filesystem separately.")
    else:
        aws(args, "cloudformation", "delete-stack", "--stack-name", args.stack)
        aws(args, "cloudformation", "wait", "stack-delete-complete", "--stack-name", args.stack)
        print("CloudFormation deletion completed. Verify that no stack resources were retained.")

def main(argv=None):
    try:
        run(parse_args(argv))
    except (subprocess.CalledProcessError, OSError, ValueError, KeyError, RuntimeError) as error:
        print("Lab operation failed: " + str(error), file=sys.stderr)
        if isinstance(error, subprocess.CalledProcessError) and error.stderr:
            print(error.stderr, file=sys.stderr)
        return 1
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
