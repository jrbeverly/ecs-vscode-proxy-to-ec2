# Execution environment identity: the disposable EC2 gets only
# AmazonSSMManagedInstanceCore — enough for the SSM agent to register and
# accept sessions, nothing else. Distinct from the workspace task role.

resource "aws_iam_instance_profile" "instance" {
  name = aws_iam_role.instance.name
  role = aws_iam_role.instance.name
}

resource "aws_iam_role_policy_attachment" "instance_ssm_core" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
