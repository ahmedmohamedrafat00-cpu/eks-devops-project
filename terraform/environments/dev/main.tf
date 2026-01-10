module "vpc" {
  source = "../../modules/vpc"

  project_name    = var.project_name
  vpc_cidr        = var.vpc_cidr
  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}
module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
}
module "eks" {
  source = "../../modules/eks"

  project_name      = var.project_name
  cluster_role_arn = module.iam.eks_cluster_role_arn
  subnet_ids        = module.vpc.private_subnet_ids
}
module "nodegroup" {
  source = "../../modules/nodegroup"

  project_name   = var.project_name
  cluster_name   = module.eks.cluster_name
  node_role_arn = module.iam.eks_node_role_arn
  subnet_ids     = module.vpc.private_subnet_ids

  desired_size = 2
  min_size     = 1
  max_size     = 3
}
module "aws_auth" {
  source = "../../modules/aws-auth"

  node_role_arn  = module.iam.eks_node_role_arn
  admin_role_arn = "<YOUR_IAM_USER_OR_ROLE_ARN>"
}
module "jenkins_ec2" {
  source        = "../../modules/ec2"
  name          = "jenkins-server"
  subnet_id     = module.vpc.private_subnet_ids[0]
  instance_type = "t3.medium"
  iam_role_arn  = module.iam.jenkins_role_arn
  security_group_ids = [module.security_groups.private_ec2_sg_id]
}

module "ansible_ec2" {
  source        = "../../modules/ec2"
  name          = "ansible-server"
  subnet_id     = module.vpc.private_subnet_ids[1]
  instance_type = "t3.micro"
  iam_role_arn  = module.iam.ansible_role_arn
  security_group_ids = [module.security_groups.private_ec2_sg_id]
}
module "security_groups" {
  source = "../../modules/security-groups"

  vpc_id           = module.vpc.vpc_id
  allowed_ssh_cidr = "197.48.122.167/32"
}
module "bastion_ec2" {
  source              = "../../modules/ec2"
  name                = "bastion-host"
  subnet_id           = module.vpc.public_subnet_ids[0]
  instance_type       = "t3.micro"
  iam_role_arn        = module.iam.jenkins_role_arn
  security_group_ids  = [module.security_groups.bastion_sg_id]
}
module "monitoring" {
  source = "../../modules/monitoring"

  project_name         = var.project_name
  alarm_email          = "ahmed.mohamed.rafat.00@gmail.com"

  jenkins_instance_id  = module.jenkins_ec2.instance_id
  ansible_instance_id  = module.ansible_ec2.instance_id
}
module "namespaces" {
  source = "../../modules/k8s-namespaces"

  namespaces = [
    "eks-build",   # Nexus
    "ingress-nginx",
    "app-dev"
  ]
}
module "ingress_nginx" {
  source    = "../../modules/ingress-nginx"
  namespace = "ingress-nginx"
}
module "nexus" {
  source    = "../../modules/nexus"
  namespace = "eks-build"
}
