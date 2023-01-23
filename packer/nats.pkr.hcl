variable "nats_version" {
  type    = string
  default = "2.9.11"
  description = "The nats-server version to use"
}

variable "ami_regions" {
    type = list(string)
    default = ["us-west-2", "us-east-1"]
    description = "Regions to copy the built AMI to"
}

variable "instance_type" {
    type = string
    default = "t2.micro"
    description = "Instance type to use for the build"
}

data "amazon-ami" "amazon_linux" {
    owners = ["amazon"]
    most_recent = true

    filters = {
        name = "amzn2-ami-hvm-*-x86_64-gp2"
    }
}

source "amazon-ebs" "nats" {
    ami_description = "NATS packer image"
    ami_name = "nats_build_{{timestamp}}"
    ami_regions = "${var.ami_regions}"
    source_ami = data.amazon-ami.amazon_linux.id
    instance_type = "${var.instance_type}"
    ssh_username = "ec2-user"
    tags = {
        Name = "nats-server"
    }
}

build {
    name = "nats"
    sources = [
        "source.amazon-ebs.nats"
    ]
    
    provisioner "shell" {
        execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
        environment_vars = ["NATS_VERSION=${var.nats_version}"]
        script = "scripts/configure.sh"
    }

    post-processor "manifest" {
        output = "manifests/nats.json"
        strip_path = true
    }
}