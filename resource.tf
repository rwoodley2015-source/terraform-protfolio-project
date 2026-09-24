resource "aws_instance" "myec2_instance" {
  ami           = "ami-0e34b50e714a297f1"
  instance_type = "t3.micro"

  tags = {
    Name = "MyEC2Instance"
  }
}