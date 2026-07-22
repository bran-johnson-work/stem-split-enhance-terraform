# Create ECR
resource "aws_ecr_repository" "ecr" {
  name                 = "${var.project}-${var.env}-${var.ecr.name}"
  image_tag_mutability = var.ecr.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.ecr.scan_on_push
  }

  tags = {
    Name = "${var.project}-${var.env}-${var.ecr.name}-ecr-repository"
  }
}

# Lifecycle policy for ECR
resource "aws_ecr_lifecycle_policy" "ecr_lifecycle_policy" {
  repository = aws_ecr_repository.ecr.name
  policy     = var.ecr_lifecycle_policy
}

resource "aws_ecr_registry_scanning_configuration" "free_tier" {
  scan_type = "BASIC"
}