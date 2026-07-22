module "ecr_api" {
  source = "../../../modules/ecr"

  env     = var.env
  project = var.project

  ecr = {
    name                 = "api"
    image_tag_mutability = "MUTABLE"
    scan_on_push         = true
  }
  ecr_lifecycle_policy = jsonencode(
    {
      "rules" : [
        {
          "rulePriority" : 10,
          "description" : "Keep last 3 untagged images",
          "selection" : {
            "tagStatus" : "untagged",
            "countType" : "imageCountMoreThan",
            "countNumber" : 3
          },
          "action" : {
            "type" : "expire"
          }
        },
        {
          "rulePriority" : 20,
          "description" : "Keep last 5 tagged images",
          "selection" : {
            "tagStatus" : "tagged",
            "tagPrefixList" : [
              var.project
            ],
            "countType" : "imageCountMoreThan",
            "countNumber" : 5
          },
          "action" : {
            "type" : "expire"
          }
        },
        {
          "rulePriority" : 30,
          "description" : "Keep last 10 images any",
          "selection" : {
            "tagStatus" : "any",
            "countType" : "imageCountMoreThan",
            "countNumber" : 10
          },
          "action" : {
            "type" : "expire"
          }
        }
      ]
    }
  )
}
