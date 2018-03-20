data "aws_availability_zones" "all" {}

data "terraform_remote_state" "db" {
  backend = "s3"

  config {
    bucket ="${var.db_remote_state_bucket}"
    key = "${var.db_remote_state_key}"
    region = "us-east-1"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user-data.sh")}"

  vars {
    server_port = "${var.serverport}"
    db_address = "${data.terraform_remote_state.db.address}"
    db_port = "${data.terraform_remote_state.db.port}"
  }
}


resource "aws_launch_configuration" "example" {
  image_id               = "ami-40d28157"
  instance_type          = "${var.instance_type}"
  security_groups = ["${aws_security_group.instance.id}"]

  user_data = "${data.template_file.user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance-sg"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "internal_http" {
    security_group_id = "${aws_security_group.instance.id}"
    type = "ingress"
    from_port   = "${var.serverport}"
    to_port     = "${var.serverport}"
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr-blocks["everyone"]}"]
}

resource "aws_security_group" "webServELBSg" {
    name = "${var.cluster_name}-asg-elb-sg"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  security_group_id = "${aws_security_group.webServELBSg.id}"
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["${var.cidr-blocks["everyone"]}"]
}

resource "aws_security_group_rule" "allow_all_outbound" {
    security_group_id = "${aws_security_group.webServELBSg.id}"
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.cidr-blocks["everyone"]}"]
}

resource "aws_autoscaling_group" "webServAsg" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  load_balancers = ["${aws_elb.elb-webServ.name}"]
  health_check_type = "ELB"

  min_size = "${var.min_size}"
  max_size = "${var.max_size}"

  tag {
    key = "Name"
    value = "${var.cluster_name}"
    propagate_at_launch = true
  }
}

resource "aws_elb" "elb-webServ" {
  name = "${var.cluster_name}-webServerElb"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups = ["${aws_security_group.webServELBSg.id}"]

  listener {
    instance_port = "${var.serverport}"
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:${var.serverport}/"
    interval = 30
  }

}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  count = "${var.enable_autoscaling}"
  scheduled_action_name = "scale-out-during-business-hours"
  min_size = 2
  max_size = 10
  desired_capacity = 6
  recurrence = "0 9 * * *"

  autoscaling_group_name = "${aws_autoscaling_group.webServAsg.name}"
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count = "${var.enable_autoscaling}"
  scheduled_action_name = "scale-in-at-night"
  min_size = 2
  max_size = 10
  desired_capacity = 2
  recurrence = "0 17 * * *"

  autoscaling_group_name = "${aws_autoscaling_group.webServAsg.name}"
}
