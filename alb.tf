#AWS Security Group to allow incomming traffic on port 80
resource "aws_security_group" "nordcloud_aelb_sg" {
  name   = "nordcloud-sg-aelb"
  vpc_id = module.vpc.vpc_id

  # Accept http traffic from the internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Accept https traffic from the internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allowing outcome traffic to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags,
    {
      "Name" = "nordcloud-aelb-sg"
  })
}

#AWS Elastic Load Balance - creating the ELB. The ELB type will be Application.
resource "aws_lb" "nordcloud_aelb" {
  name               = "nordcloud-aelb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.nordcloud_aelb_sg.id]
  subnets            = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]

  tags = merge(var.tags,
    {
      "Name" = "nordcloud-aelb"
  })
}

#Creating the AELB's target group 
resource "aws_lb_target_group" "nordcloud_aelb_tg" {
  name                 = "nordcloud-tg"
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 180
  vpc_id               = module.vpc.vpc_id

  health_check {
    healthy_threshold = 3
    interval          = 10
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }

  tags = merge(var.tags,
    {
      "Name" = "nordcloud-aelb"
  })
}

#Setting the AELB to listening HTTP, port 80, and foward the 
resource "aws_lb_listener" "nordcloud_aelb_listener" {
  load_balancer_arn = aws_lb.nordcloud_aelb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nordcloud_aelb_tg.arn
  }
}
