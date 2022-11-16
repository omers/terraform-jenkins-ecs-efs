# ecs.tf | Elastic Container Service Cluster and Tasks Configuration

resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "${var.app_name}-${var.app_environment}-cluster"
  tags = {
    Name        = "${var.app_name}-ecs"
    Environment = var.app_environment
  }
}

resource "aws_cloudwatch_log_group" "log-group" {
  name = "${var.app_name}-${var.app_environment}-logs"

  tags = {
    Application = var.app_name
    Environment = var.app_environment
  }
}

data "template_file" "env_vars" {
  template = file("env_vars.json")
}

resource "aws_ecs_task_definition" "aws-ecs-task" {
  family = "${var.app_name}-task"

  container_definitions = <<DEFINITION
  [
    {
      "name": "${var.app_name}-${var.app_environment}-container",
      "image": "jenkins/jenkins",
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.log-group.id}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "${var.app_name}-${var.app_environment}"
        }
      },
      "portMappings": [
        {
          "containerPort": ${var.app_port},
          "hostPort": ${var.app_port}
        }
      ],
      "cpu": 1024,
      "memory": 2048,
      "networkMode": "awsvpc",
      "mountPoints": [
                {
                    "containerPath": "/var/jenkins_home",
                    "sourceVolume": "n8n-storage"
                }
      ]
    }
  ]
  DEFINITION
   volume {
    name      = aws_efs_file_system.efs.creation_token
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.efs.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.default.id
        iam             = "DISABLED"
      }
    }
  }
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "4096"
  cpu                      = "2048"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn

  tags = {
    Name        = "${var.app_name}-ecs-td"
    Environment = var.app_environment
  }
}

data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.aws-ecs-task.family
}

resource "aws_ecs_service" "aws-ecs-service" {
  name            = "${var.app_name}-${var.app_environment}-ecs-service"
  cluster         = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition = "${aws_ecs_task_definition.aws-ecs-task.family}:${max(aws_ecs_task_definition.aws-ecs-task.revision, data.aws_ecs_task_definition.main.revision)}"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 10
    base              = 2
  }
  network_configuration {
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
    security_groups = [
      aws_security_group.service_security_group.id,
      aws_security_group.load_balancer_security_group.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "${var.app_name}-${var.app_environment}-container"
    container_port   = var.app_port
  }

  depends_on = [aws_lb_listener.listener]
}

resource "aws_security_group" "service_security_group" {
  vpc_id = aws_vpc.aws-vpc.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.app_name}-service-sg"
    Environment = var.app_environment
  }
}

