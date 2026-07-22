#IAM Role
resource "aws_iam_role" "iam_role" {
  name               = "${var.project}-${var.env}-${var.name}-role"
  description        = "${var.project}-${var.env} : ${var.service}"
  assume_role_policy = var.assume_role_policy

  tags = {
    Service = var.service
  }
}

#IAM Default Policy
resource "aws_iam_role_policy_attachment" "iam_default_policy" {
  count = length(var.iam_default_policy_arn)

  role       = aws_iam_role.iam_role.name
  policy_arn = element(var.iam_default_policy_arn, count.index)
}

#IAM Custom Policy
resource "aws_iam_role_policy" "iam_custom_policy" {
  count = var.iam_custom_policy != null ? 1 : 0

  name   = "${var.project}-${var.env}-${var.name}-policy"
  role   = aws_iam_role.iam_role.id
  policy = var.iam_custom_policy.template
}

#Instance Profile
resource "aws_iam_instance_profile" "iam_instance_profile" {
  count = var.iam_instance_profile == true ? 1 : 0

  name = "${var.project}-${var.env}-${var.name}-instance-profile"
  role = aws_iam_role.iam_role.name
}
