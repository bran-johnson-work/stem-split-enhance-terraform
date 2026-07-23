#IAM User — for principals that run OUTSIDE AWS (no instance profile / IMDS), e.g.
#a GPU worker rented on vast.ai. Access keys are intentionally NOT created here:
#minting them in Terraform would store the secret in state. Create the access key
#in the console (or `aws iam create-access-key`) and place it in the host's .env.
resource "aws_iam_user" "iam_user" {
  name = "${var.project}-${var.env}-${var.name}-user"
}

#Inline custom policy (scoped permissions for this user).
resource "aws_iam_user_policy" "iam_custom_policy" {
  count = var.iam_custom_policy != null ? 1 : 0

  name   = "${var.project}-${var.env}-${var.name}-policy"
  user   = aws_iam_user.iam_user.name
  policy = var.iam_custom_policy.template
}
