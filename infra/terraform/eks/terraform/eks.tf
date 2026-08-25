# EKS control plane, managed node group, and the OIDC provider that makes IRSA
# possible. Depends on vpc through the plan DAG; the subnet ids arrive as
# lease-published values, not as a terraform_remote_state data source.

locals {
  cluster_name        = "${local.name_prefix}-eks"
  private_subnet_ids  = compact(split(",", var.privateSubnetIds))
  public_subnet_ids   = compact(split(",", var.publicSubnetIds))
  endpoint_cidrs      = compact(split(",", var.publicEndpointCidrs))
  node_instance_types = compact(split(",", var.nodeInstanceTypes))
}

data "aws_iam_policy_document" "cluster_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${local.cluster_name}-cluster"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume.json
}

resource "aws_iam_role_policy_attachment" "cluster" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
  ])
  role       = aws_iam_role.cluster.name
  policy_arn = each.value
}

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = 30
}

resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetesVersion

  # The API server audit trail. Enabled here rather than "when we need it",
  # because when you need it is after the thing you wanted to audit happened.
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    subnet_ids = concat(local.private_subnet_ids, local.public_subnet_ids)

    # Private endpoint always on — in-cluster and VPC traffic reaches the API
    # server without leaving the VPC. The public endpoint is on ONLY when
    # someone supplied an explicit allow-list.
    endpoint_private_access = true
    endpoint_public_access  = length(local.endpoint_cidrs) > 0
    public_access_cidrs     = length(local.endpoint_cidrs) > 0 ? local.endpoint_cidrs : null
  }

  access_config {
    # API-based access entries rather than the aws-auth ConfigMap. The ConfigMap
    # is a single cluster-wide object that every automation edits by read-modify-
    # write; two concurrent applies silently clobber each other's entries.
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.cluster.arn
    }
    resources = ["secrets"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster,
    aws_cloudwatch_log_group.cluster,
  ]
}

resource "aws_kms_key" "cluster" {
  description             = "Envelope encryption for ${local.cluster_name} Kubernetes secrets"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "cluster" {
  name          = "alias/${local.cluster_name}-secrets"
  target_key_id = aws_kms_key.cluster.key_id
}

# ---------------------------------------------------------------------------
# IRSA. The OIDC provider is what lets a ServiceAccount annotation stand in for
# an access key, which is why no node in this estate carries application
# permissions.
# ---------------------------------------------------------------------------

data "tls_certificate" "oidc" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc" {
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
}

# ---------------------------------------------------------------------------
# Managed node group
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "node_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${local.cluster_name}-node"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    # Pull-only. Nodes must never be able to push an image: a compromised pod
    # that can overwrite the tag it was started from is a persistence mechanism.
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ])
  role       = aws_iam_role.node.name
  policy_arn = each.value
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.cluster_name}-default"
  node_role_arn   = aws_iam_role.node.arn
  # Nodes never sit in a public subnet. Egress is via NAT; ingress is via the
  # ALB, which targets pod IPs directly.
  subnet_ids     = local.private_subnet_ids
  instance_types = local.node_instance_types
  capacity_type  = var.nodeCapacityType

  scaling_config {
    desired_size = var.nodeDesiredSize
    min_size     = var.nodeMinSize
    max_size     = var.nodeMaxSize
  }

  update_config {
    max_unavailable = 1
  }

  lifecycle {
    # The desired size drifts as the cluster autoscaler works. Terraform
    # re-asserting it on every apply would fight the autoscaler and scale the
    # fleet down mid-day.
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [aws_iam_role_policy_attachment.node]
}

# ---------------------------------------------------------------------------
# Cluster add-ons managed by EKS itself rather than by Helm: these are cluster
# infrastructure, and a Helm release that fails to upgrade should not be able to
# take the CNI with it.
# ---------------------------------------------------------------------------

resource "aws_eks_addon" "core" {
  for_each = toset(["vpc-cni", "coredns", "kube-proxy"])

  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = each.value
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [aws_eks_node_group.main]
}
