# Terraform resources for CV project branch rollover ECS usage
resource "aws_ecs_cluster" "cv_task_cluster" {
  name               = "cv_task_cluster-${var.env_aws_profile}"
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
}

resource "aws_ecs_task_definition" "rollover_task_def" {
  family                   = "rollover_task_def-${var.env_aws_profile}"
  task_role_arn            = aws_iam_role.rollover_ecs_task_role.arn
  execution_role_arn       = aws_iam_role.rollover_ecs_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  container_definitions = <<TASK_DEFINITION
[
  {
    "dnsSearchDomains": null,
    "environmentFiles": null,
    "logConfiguration": {
      "logDriver": "awslogs",
      "secretOptions": null,
      "options": {
        "awslogs-group": "/ecs/rollover_task_def-${var.env_aws_profile}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "entryPoint": null,
    "portMappings": [],
    "command": null,
    "linuxParameters": null,
    "cpu": 0,
    "environment": [
      {
        "name": "CUSTOMER_NAME",
        "value": ""
      },
      {
        "name": "ENVIRONMENT_NAME",
        "value": ""
      },
      {
        "name": "TARGET_ENVIRONMENT",
        "value": ""
      },
      {
        "name": "TARGET_ACCOUNT_ID",
        "value": ""
      },
      {
        "name": "CUSTOMER_REGION",
        "value": ""
      },
      {
        "name": "ROLLOVER_PROCESS_ID",
        "value": ""
      },
      {
        "name": "PROCESS_OP",
        "value": ""
      }
    ],
    "resourceRequirements": null,
    "ulimits": null,
    "dnsServers": null,
    "mountPoints": [],
    "workingDirectory": null,
    "secrets": null,
    "dockerSecurityOptions": null,
    "memory": 512,
    "memoryReservation": null,
    "volumesFrom": [],
    "stopTimeout": null,
    "image": "${var.sst_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/cv_ecs:latest",
    "startTimeout": null,
    "firelensConfiguration": null,
    "dependsOn": null,
    "disableNetworking": null,
    "interactive": null,
    "healthCheck": null,
    "essential": true,
    "links": null,
    "hostname": null,
    "extraHosts": null,
    "pseudoTerminal": null,
    "user": null,
    "readonlyRootFilesystem": null,
    "dockerLabels": null,
    "systemControls": null,
    "privileged": null,
    "name": "rollover_container-${var.env_aws_profile}"
  }
]
TASK_DEFINITION
}

data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    sid = ""

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rollover_ecs_task_role" {
  name               = "rollover_task_role-${var.env_aws_profile}"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

data "aws_iam_policy_document" "rollover_task_policy_doc" {
  statement {
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
    ]
    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
  statement {
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::axiom-solution-deployment-${var.customer}-${var.env}",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-data",
      "arn:aws:s3:::axiom-${var.customer}-01-client-repo",
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]
    resources = [
      "arn:aws:s3:::axiom-solution-deployment-${var.customer}-${var.env}/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-data/*",
      "arn:aws:s3:::axiom-${var.customer}-01-client-repo/*",
    ]
  }

  statement {
    actions = [
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::axiom-solution-deployment-${var.customer}-${var.env}/*",
    ]
  }

  statement {
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [
      "arn:aws:kms:*:*:key/*",
    ]
  }

  statement {
    actions = [
      "sqs:SendMessage",
    ]
    resources = [
      "arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:cv_process_queue-${var.customer}-${var.env}",
    ]
  }

  statement {
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::*:role/cross_cv_lambda_role-*",
    ]
  }

  statement {
    actions = [
      "ec2:DescribeVpcEndpoints",
      "ec2:DeleteVpcEndpoints",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "rollover_task_policy" {
  name        = "rollover_task_policy-${var.customer}-${var.env}"
  path        = "/"
  description = "Allow CV rollover Task to access CV deployment resources and buckets"
  policy      = data.aws_iam_policy_document.rollover_task_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "rollover_task_policy_att" {
  role       = aws_iam_role.rollover_ecs_task_role.name
  policy_arn = aws_iam_policy.rollover_task_policy.arn
}

resource "aws_iam_role_policy_attachment" "rollover_task_sqs" {
  role       = aws_iam_role.rollover_ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "rollover_task_lambdarole" {
  role       = aws_iam_role.rollover_ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

resource "aws_iam_role" "rollover_ecs_task_execution_role" {
  name               = "rollover_task_execution_role-${var.env_aws_profile}"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

resource "aws_iam_role_policy_attachment" "rollover_task_execution_policy_att" {
  role       = aws_iam_role.rollover_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
