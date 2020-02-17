resource "aws_security_group" "eks-node" {
  name        = "terraform-eks-eks-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name"                                      = "${var.cluster_name}-node"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_security_group_rule" "eks-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks-node.id
  source_security_group_id = aws_security_group.eks-node.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-node.id
  source_security_group_id = aws_security_group.eks-cluster.id
  to_port                  = 65535
  type                     = "ingress"
}

# for api metrics
resource "aws_security_group_rule" "eks-cluster-ingress-cluster-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-node.id
  source_security_group_id = aws_security_group.eks-cluster.id
  to_port                  = 443
  type                     = "ingress"
}

# Connects workers to master
resource "aws_security_group_rule" "eks-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-cluster.id
  source_security_group_id = aws_security_group.eks-node.id
  to_port                  = 443
  type                     = "ingress"
}

# Connects workers to load balancers
resource "aws_security_group_rule" "eks-node-ingress-lb" {
  description              = "Allow worker pods to receive communication from the load balancers"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-node.id
  source_security_group_id = aws_security_group.eks-lb.id
  type                     = "ingress"
}

//# security group - hardening egress
//resource "aws_security_group_rule" "eks-node-egress-lb-http" {
//  description       = "Allow worker pods to create communication to the load balancers over http"
//  type              = "egress"
//  from_port         = 80
//  to_port           = 80
//  protocol          = "tcp"
//  security_group_id = aws_security_group.eks-node.id
//  source_security_group_id = aws_security_group.eks-lb.id
//}
//
//# security group - hardening egress
//resource "aws_security_group_rule" "eks-node-egress-lb-https" {
//  description       = "Allow worker pods to create communication to the load balancers over https"
//  type              = "egress"
//  from_port         = 443
//  to_port           = 443
//  protocol          = "tcp"
//  security_group_id = aws_security_group.eks-node.id
//  source_security_group_id = aws_security_group.eks-lb.id
//}
//
//resource "aws_security_group_rule" "eks-node-egress-cluster-https" {
//  description              = "Allow worker Kubelets and pods to create communication to the cluster control plane over https"
//  type                     = "egress"
//  from_port                = 443
//  to_port                  = 443
//  protocol                 = "tcp"
//  security_group_id        = aws_security_group.eks-node.id
//  source_security_group_id = aws_security_group.eks-cluster.id
//}