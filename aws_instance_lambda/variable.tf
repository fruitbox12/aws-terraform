variable "region" {
    default = "us-east-1"
}

variable "cidr" {
    default = "10.0.0.0/16"
}

variable "public_cidr" {
    default = "10.0.0.0/24"
}

variable "general_cidr" {
    default = "0.0.0.0/0"
}

variable "instance_type" {
    default = "t2.micro"
}

variable "ami"{
    default = "ami-0885b1f6bd170450c" #get ami from the region you choose to launch the stack.(default is us-east-1 region)
}

variable "key_name" {
    default = "terraform"  # enter the key name in the region you wish to launch the instance
}