################################################################################
# Vault Cluster – ECS Fargate with AWS KMS Auto-Unseal & DynamoDB HA Backend
################################################################################

locals {
  name_prefix = "${var.cluster_name}-${var.environment}"
  vault_image = "hashicorp/vault:${var.vault_version}"

  vault_env = {
    VAULT_ADDR            = "http://127.0.0.1:8200"
    VAULT_API_ADDR        = "https://${var.domain_name}"
    VAULT_CLUSTER_ADDR    = "https://${var.domain_name}:8201"
    VAULT_LOG_LEVEL       = var.log_level
    AWS_DEFAULT_REGION    = data.aws_region.current.name
    VAULT_SEAL_TYPE       = "awskms"
    VAULT_AWSKMS_SEAL_KEY = var.kms_key_arn
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ------------------------------------------------------------------------------
# KMS Key for Auto-Unseal (use provided or create)
# ------------------------------------------------------------------------------
resource "aws_kms_key" "vault_unseal" {
  count                   = var.kms_key_arn == "" ? 1 : 0
  description             = "Vault auto-unseal key for ${local.name_prefix}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = merge(var.tags, { Name = "${local.name_prefix}-unseal" })
}

resource "aws_kms_alias" "vault_unseal" {
  count         = var.kms_key_arn == "" ? 1 : 0
  name          = "alias/${local.name_prefix}-unseal"
  target_key_id = aws_kms_key.vault_unseal[0].key_id
}

locals {
  kms_key_arn = var.kms_key_arn != "" ? var.kms_key_arn : aws_kms_key.vault_unseal[0].arn
}

# ------------------------------------------------------------------------------
# DynamoDB Table – HA Storage Backend
# ------------------------------------------------------------------------------
resource "aws_dynamodb_table" "vault_storage" {
  name         = "${local.name_prefix}-storage"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Path"
  range_key    = "Key"

  attribute {
    name = "Path"
    type = "S"
  }

  attribute {
    name = "Key"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = local.kms_key_arn
  }

  tags = merge(var.tags, { Name = "${local.name_prefix}-storage" })
}

# ------------------------------------------------------------------------------
# CloudWatch Log Group
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "vault" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = var.log_retention_days
  kms_key_id        = local.kms_key_arn
  tags              = var.tags
}

# ------------------------------------------------------------------------------
# IAM – Task Execution Role
# ------------------------------------------------------------------------------
resource "aws_iam_role" "ecs_execution" {
  name = "${local.name_prefix}-ecs-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ------------------------------------------------------------------------------
# IAM – Vault Task Role (KMS + DynamoDB + Logs)
# ------------------------------------------------------------------------------
resource "aws_iam_role" "vault_task" {
  name = "${local.name_prefix}-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "vault_kms" {
  name = "${local.name_prefix}-kms"
  role = aws_iam_role.vault_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey"
      ]
      Resource = local.kms_key_arn
    }]
  })
}

resource "aws_iam_role_policy" "vault_dynamodb" {
  name = "${local.name_prefix}-dynamodb"
  role = aws_iam_role.vault_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:UpdateItem"
      ]
      Resource = aws_dynamodb_table.vault_storage.arn
    }]
  })
}

resource "aws_iam_role_policy" "vault_logs" {
  name = "${local.name_prefix}-logs"
  role = aws_iam_role.vault_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.vault.arn}:*"
    }]
  })
}

# ------------------------------------------------------------------------------
# Security Group – Vault Service
# ------------------------------------------------------------------------------
resource "aws_security_group" "vault" {
  name_prefix = "${local.name_prefix}-vault-"
  description = "Vault server security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Vault API from ALB"
    from_port       = 8200
    to_port         = 8200
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "Vault cluster (HA)"
    from_port   = 8201
    to_port     = 8201
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name_prefix}-vault" })

  lifecycle { create_before_destroy = true }
}

# ------------------------------------------------------------------------------
# Security Group – ALB
# ------------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name_prefix = "${local.name_prefix}-alb-"
  description = "Vault ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name_prefix}-alb" })

  lifecycle { create_before_destroy = true }
}

# ------------------------------------------------------------------------------
# ACM Certificate
# ------------------------------------------------------------------------------
resource "aws_acm_certificate" "vault" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  tags              = merge(var.tags, { Name = "${local.name_prefix}-cert" })

  lifecycle { create_before_destroy = true }
}

# ------------------------------------------------------------------------------
# Internal ALB
# ------------------------------------------------------------------------------
resource "aws_lb" "vault" {
  name               = "${local.name_prefix}-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = var.environment == "prod" ? true : false

  tags = merge(var.tags, { Name = "${local.name_prefix}-alb" })
}

resource "aws_lb_target_group" "vault" {
  name        = "${local.name_prefix}-tg"
  port        = 8200
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/v1/sys/health?standbyok=true&sealedcode=200&uninitcode=200"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }

  tags = var.tags
}

resource "aws_lb_listener" "vault" {
  load_balancer_arn = aws_lb.vault.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.vault.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vault.arn
  }
}

# ------------------------------------------------------------------------------
# ECS Cluster
# ------------------------------------------------------------------------------
resource "aws_ecs_cluster" "vault" {
  name = local.name_prefix

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

# ------------------------------------------------------------------------------
# ECS Task Definition
# ------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "vault" {
  family                   = local.name_prefix
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.vault_task.arn

  container_definitions = jsonencode([{
    name      = "vault"
    image     = local.vault_image
    essential = true

    command = ["vault", "server", "-config=/vault/config/vault-config.hcl"]

    portMappings = [
      { containerPort = 8200, protocol = "tcp" },
      { containerPort = 8201, protocol = "tcp" }
    ]

    environment = [for k, v in local.vault_env : { name = k, value = v }]

    linuxParameters = {
      capabilities = { add = ["IPC_LOCK"] }
    }

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.vault.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "vault"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "vault status -address=http://127.0.0.1:8200 || exit 1"]
      interval    = 15
      timeout     = 5
      retries     = 3
      startPeriod = 30
    }
  }])

  tags = var.tags
}

# ------------------------------------------------------------------------------
# ECS Service
# ------------------------------------------------------------------------------
resource "aws_ecs_service" "vault" {
  name            = local.name_prefix
  cluster         = aws_ecs_cluster.vault.id
  task_definition = aws_ecs_task_definition.vault.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.vault.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.vault.arn
    container_name   = "vault"
    container_port   = 8200
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [aws_lb_listener.vault]

  tags = var.tags
}
