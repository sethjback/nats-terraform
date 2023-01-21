Build Immutable NATS AMI
---

Packer configuration to build a NATS AMI.

This will build an Amazon Machine Image (AMI) that is configured to run `nats-server`. It uses Amazon Linux 2 as the base image.

A default, basic, Jetstream Enabled configuration is provided. It is intended to be used with terraform that will provide an appropriate configuration via the instance metadata on boot.

## Required Environment Variables

This script assumes you have the necessary AWS variables set to access the required resources to run packer. For example, the AWS envars:

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_DEFAULT_REGION
```

Additionally, you will need the correct AWS permissions to create the EC2 resources needed to run. For the minimum required permissions as well as options for configuring AWS access, see the [official documentation](https://developer.hashicorp.com/packer/plugins/builders/amazon#authentication)

## Configuration

The following variables are needed

name | default value | description
--|--|--
`nats_version` | `2.9.11` | nats server version to install
`ami_regions` | `["us-west-2","us-east-1"]` | list of regions to copy the resulting AMI to
`instance_type` | `t2.micro` | instance type to use as the builder
