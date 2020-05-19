######### IAM ####################

# Create an IAM role for the auto-join
resource "aws_iam_role" "consul-join" {
  name               = "final-consul-join"
  assume_role_policy = file("${path.module}/policies/assume-role-consul.json")
}

# Create the policy
resource "aws_iam_policy" "consul-join" {
  name        = "final-consul-join"
  description = "Allows Consul nodes to describe instances for joining."
  policy      = file("${path.module}/policies/describe-instances-consul.json")
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



# ######### IAM Jenkins####################
# ## Jenkins IAM Resources ##
# resource "aws_iam_role" "final-jenkins_eks" {
#   name = "final-jenkins_eks"
#   assume_role_policy = file("${path.module}/eks/templates/policies/eks_jenkins_iam_role.json")
# }

# # Create the policy
# resource "aws_iam_policy" "final-jenkins_eks" {
#   name = "final-jenkins_eks"
#   policy = file("${path.module}/eks/templates/policies/eks_jenkins_iam_policy.json")
# }


# # Attach the policy
# resource "aws_iam_policy_attachment" "final-jenkins_eks" {
#   name       = "final-jenkins_eks"
#   roles      = ["${aws_iam_role.final-jenkins_eks.name}"]
#   policy_arn = aws_iam_policy.final-jenkins_eks.arn
# }

# # Create the instance profile
# resource "aws_iam_instance_profile" "final-jenkins_eks" {
#   name  = "final-jenkins_eks"
#   role = aws_iam_role.final-jenkins_eks.name
# }