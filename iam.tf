resource "aws_iam_instance_profile" "ec2_profile_east1" {
  name = "ec2-profile-east1"
  role = aws_iam_role.ec2_role_east1.name
}

resource "aws_iam_role" "ec2_role_east1" {
  name = "ec2-role-east1"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}  
EOF
}

resource "aws_iam_role_policy_attachment" "attach_to_ssm" {
  role       = aws_iam_role.ec2_role_east1.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "attach_to_s3" {
  role       = aws_iam_role.ec2_role_east1.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "attach_to_cloud_watch" {
  role       = aws_iam_role.ec2_role_east1.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}