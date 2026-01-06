module "vpc" {
  source = "../../modules/vpc"

  project_name    = local.project_name
  vpc_cidr        = "10.0.0.0/16"
  azs             = ["eu-central-1a", "eu-central-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
}
module "iam" {
  source = "../../modules/iam"

  project_name = local.project_name
}
module "eks" {
  source = "../../modules/eks"

  project_name      = local.project_name
  cluster_role_arn = module.iam.eks_cluster_role_arn
  subnet_ids        = module.vpc.private_subnet_ids
}
