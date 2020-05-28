######### IAM ####################

# Create an IAM role for the auto-join
resource "aws_iam_role" "consul-join" {
  name               = "final-consul-join"
  assume_role_policy = file("${path.module}/policies/assume-role.json")
}

# Create the policy
resource "aws_iam_policy" "consul-join" {
  name        = "final-consul-join"
  description = "Allows Consul nodes to describe instances for joining."
  policy      = file("${path.module}/policies/describe-instances.json")
}

# Attach the policy
resource "aws_iam_policy_attachment" "consul-join" {
  name       = "final-consul-join"
  roles      = ["${aws_iam_role.consul-join.name}"]
  policy_arn = aws_iam_policy.consul-join.arn
}

# Create the instance profile
resource "aws_iam_instance_profile" "consul-join" {
  name = "final-consul-join"
  role = aws_iam_role.consul-join.name
}



######### IAM EKS ####################
##  IAM Resources ##
resource "aws_iam_role" "opsschool-final-eks" {
  name = "opsschool-final-eks"
  assume_role_policy = file("${path.module}/policies/assume-role.json")
}

# Create the policy
resource "aws_iam_policy" "opsschool-eks-describe" {
  name = "opsschool-eks-describe"
  policy = file("${path.module}/policies/describe-eks.json")
  description = "Allows to describe EKS for joining."
}

# Attach the policy
resource "aws_iam_role_policy_attachment" "opsschool-eks-describe" {
  role      = aws_iam_role.opsschool-final-eks.name
  policy_arn = aws_iam_policy.opsschool-eks-describe.arn
}

# Attach the policy
resource "aws_iam_role_policy_attachment" "opsschool-eks-clusterpolicy" {
  role       = aws_iam_role.opsschool-final-eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
# Attach the policy
resource "aws_iam_role_policy_attachment" "opsschool-eks-servicepolicy" {
  role       = aws_iam_role.opsschool-final-eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# Create the instance profile
resource "aws_iam_instance_profile" "opsschool-deploy-app" {
  name  = "opsschool-deploy-app"
  role = aws_iam_role.opsschool-final-eks.name
}