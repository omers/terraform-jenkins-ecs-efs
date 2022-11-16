resource "aws_efs_file_system" "efs" {
  creation_token = "n8n-storage"

  tags = {
    Name = "n8n-storage"
  }
}

resource "aws_efs_mount_target" "main" {
  count = length(var.private_subnets)
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  security_groups = [aws_security_group.efs.id]
}

resource "aws_security_group" "efs" {
  name        = "efs-security-group"
  vpc_id      = aws_vpc.aws-vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = 2049
    to_port         = 2049
    security_groups = [aws_security_group.service_security_group.id]
    cidr_blocks = [for net in aws_subnet.private : net.cidr_block]
  }
  ingress {
    protocol        = "tcp"
    from_port       = 2999
    to_port         = 2999
    security_groups = [aws_security_group.service_security_group.id]
    cidr_blocks = [for net in aws_subnet.private : net.cidr_block]
  }
}

resource "aws_efs_access_point" "default" {
  file_system_id = aws_efs_file_system.efs.id
  posix_user {
    uid = 1000
    gid = 1000
  }
  root_directory {
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 755
    }
    path = "/var/jenkins_home"
  }
}