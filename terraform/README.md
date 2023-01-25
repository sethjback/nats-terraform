Deploy a NATS Cluster
---

Terraform module to deploy a NATS cluster to a single AWS region.

## Required AMI

This relies on a nats AMI to be present in the region being deployed to. See the [packer](https://github.com/sethjback/nats-terraform/tree/main/packer) section of this repo for an easy way to build one.

If using a custom AMI this assumes `nats-server` lives in `/opt/nats` and is using `/opt/nats/nats-config` as its config file.

## Required Environment Variables

This assumes you have the necessary AWS variables set to access the required resources to run packer. For example, the AWS envars:

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
```

## Resources Created

This module will create several resources:

1. VPC

If you do not specify an existing vpc id to deploy into one will be created with subnets in each of the availability zones.

2. IAM Role

This module dynamically creates a valid NATS config on instance start based on the deployed nats instances in the region. To accomplish this each instance needs to be able to run the `aws ec2 describe-instances` command. An IAM policy, role, attachment, and instance profile is created to with the minimal permissions required for this. Each instances is launched with this role.

3. Security Group

A security group is created that allows incoming access to the nats, cluster, and http monitoring port, as well as outgoing access to the internet.

4. EC2 instances

the number of requested instances is created

## TFVars

| name | default | description |
|--|--|--|
| vpc_id | null | ID of the vpc to deploy into. If null one will be created |
| public_access | true | Allow external access (expose port 4222) to the NATS cluster. |
| server_count | 3 | Number of servers to deploy. 3 or an odd number is recommend. |
| cluster_name | nats-cluster | What to name the cluster |
| enable_js | true | Enable JS on the cluster
| availability_zones | null | List of AZs to deploy into. Instances will be randomly spread across these |
| instance_type | t2.micro | Instance type to use for the servers |
| operator_jwt | -- | the operator JWT for this cluster |
| system_account_id | -- | SYS account id |
| system_account_jwt | -- | jwt for the SYS account signed by the operator |