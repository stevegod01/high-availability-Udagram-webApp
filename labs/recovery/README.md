# Recovery planning exercise: VPC and ECS foundation

These are adapted historical examples from [DR-Template](https://github.com/stevegod01/DR-Template) at `47312287989c15513c8d3e2409c55735e3c9fd26`. Recent commits there identify Joseph Chima; authorship is not reassigned here. Original files remain in [source history](../../docs/history/DR-Template/). The only adaptation to the VPC copy replaces constructed AZ names with `GetAZs`/`Select`.

The first template creates a VPC, three public and three private subnets, an internet gateway and **one shared NAT gateway**. It requires at least three available AZs. The second creates an empty ECS cluster with Fargate capacity-provider settings (Spot in Dev/Stage, regular Fargate in Prod). It creates no tasks, service, database, restore operation, replication or backups. The shared NAT is an egress failure point. Static template validation is not a disaster-recovery test.

## Template exercise

Validate from the repository root with `cfn-lint labs/recovery/*.yaml`. To deliberately provision the foundation, use AWS CLI v2 and a dedicated test account/region with the declared EC2/VPC/ECS permissions:

```sh
export AWS_REGION=us-east-1
aws cloudformation deploy --stack-name recovery-network-lab --template-file labs/recovery/001ProdVpc.yaml --parameter-overrides EnvironmentNameLower=dev Cidr=10.70.0.0/16 SubnetCidrPrefix=10.70
aws cloudformation deploy --stack-name recovery-cluster-lab --template-file labs/recovery/002ProdEcsCluster.yaml --parameter-overrides EnvironmentName=Dev ServiceNameDashy=recovery-lab
aws cloudformation describe-stack-resources --stack-name recovery-network-lab
aws cloudformation describe-stack-resources --stack-name recovery-cluster-lab
```

NAT, public IPv4 and traffic incur costs even with no application running. The templates are independent; the empty ECS cluster has no attached workload/network configuration. Verify resources and route associations, then remove the cluster and network stacks using `aws cloudformation delete-stack` followed by `aws cloudformation wait stack-delete-complete` for each named stack. No deployment was performed for this revision.

## Honest recovery runbook

Use this checklist to design a future exercise, not as a claim that recovery is implemented:

1. **Define scope and owner.** Identify the application, database, object stores, region/account, dependencies and approved isolated test environment. Agree business RTO and RPO with the owner; values are **not yet defined** here.
2. **Prepare recoverable inputs.** Record the exact container digest, task/service definitions, IAM roles, network mappings, secret references, backups and restore procedures. The two templates alone are insufficient. Verify that backups can be read and restored in the target environment.
3. **Establish a baseline.** Capture application health and a known test record with timestamp; verify the most recent recoverable backup. Record estimated costs and a rollback/abort owner.
4. **Run an approved simulation.** In an isolated environment, simulate the agreed failure. Start the outage timer. Provision the network/cluster, restore state, register the intended task definition, deploy the service and repair only the required routing/DNS. Never test failure by disrupting production implicitly.
5. **Validate recovery.** Check health, authentication, data consistency, background processing and dependency access. Record outage-to-healthy duration and the timestamp gap between the last pre-failure record and recovered data. Compare measured outcomes with the agreed targets.
6. **Close and clean up.** Record failures and corrective work, verify the normal environment, remove disposable resources in dependency order and retain logs/checksums without secrets.

| Evidence | Current state |
| --- | --- |
| Recovery objectives agreed | Not supplied |
| Application/database restore implementation | Not included |
| CloudFormation schema checks | Provided by validation workflow |
| Recovery drill and measured RTO/RPO | Not performed |

Do not publish a successful recovery or a numeric RTO/RPO until the application, restore process and exercise evidence exist.
