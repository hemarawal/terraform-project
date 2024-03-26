resource "aws_key_pair" "key_pair" {
  key_name   = "terra-key"
  public_key = file(var.key_pair_public_key_path)
}

resource "aws_default_vpc" "default" {}

resource "aws_security_group" "terra_sg" {
  name   = "my-security-group"
  vpc_id = aws_default_vpc.default.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    description = "Outgoing traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }
}

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.key_pair.key_name
  security_groups = [aws_security_group.terra_sg.name]

  tags = {
    Name = "terra-instance"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install nginx -y",
      "sudo systemctl start nginx"
    ]
  }

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }
}

resource "aws_ebs_volume" "myebsvol" {
  availability_zone = aws_instance.web.availability_zone
  size              = var.ebs_volume_size
  # You can customize other properties of the EBS volume here
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = var.ebs_device_name
  instance_id = aws_instance.web.id
  volume_id   = aws_ebs_volume.myebsvol.id
}
