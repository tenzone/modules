output "elb_dns_name" {
  value = "${aws_elb.elb-webServ.dns_name}"
}
output "asg_name" {
  value = "${aws_autoscaling_group.webServAsg.name}"
}

output "elb_security_group_id" {
  value = "${aws_security_group.webServELBSg.id}"
}
