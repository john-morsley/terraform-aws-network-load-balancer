#      _   _  _____ _____ _   ___   __  __ 
#     | \ | |/ ____|_   _| \ | \ \ / / /_ |
#     |  \| | |  __  | | |  \| |\ V /   | |
#     | . ` | | |_ | | | | . ` | > <    | |
#     | |\  | |__| |_| |_| |\  |/ . \   | |
#     |_| \_|\_____|_____|_| \_/_/ \_\  |_|

module "nginx-1-ec2" {

  source = "john-morsley/ec2/aws"

  name = local.ec2_1_name

  ami = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type

  vpc_id = module.load-balancer-vpc.id

  iam_instance_profile_name = module.ec2-iam-role.instance_profile_name

  public_subnet_id = module.load-balancer-vpc.public_subnet_ids[0]

  security_group_ids = [
    module.allow-all-sg.id
  ]

  availability_zone = data.aws_availability_zones.available.names[0]

  bucket_name = local.bucket_name

  docker = false

  mock_depends_on = [
    module.load-balancer-s3-bucket
  ]

}

resource "local_file" "index-1" {

  content  = templatefile("${path.module}/html/index.tpl", { EC2_NAME = "EC2 - 1" })
  filename = "${path.module}/html/index-1.html"

}

resource "null_resource" "install-nginx-1" {

  depends_on = [
    #null_resource.get-shared-scripts,
    local_file.index-1,
    module.nginx-1-ec2
  ]

  connection {
    type        = "ssh"
    host        = module.nginx-1-ec2.public_ip
    user        = "ubuntu"
    private_key = base64decode(module.nginx-1-ec2.encoded_private_key)
  }

  # https://www.terraform.io/docs/provisioners/file.html

  provisioner "file" {
    #source      = "${path.cwd}/${local.shared_scripts_folder}/docker/install_docker.sh"
    source      = "${path.cwd}/scripts/install_nginx.sh"
    destination = "install_nginx.sh"
  }

  provisioner "file" {
    #source      = "${path.cwd}/${local.shared_scripts_folder}/docker/install_docker.sh"
    source      = "${path.cwd}/html/index-1.html"
    destination = "index.html"
  }

  # https://www.terraform.io/docs/provisioners/remote-exec.html

  provisioner "remote-exec" {
    inline = ["chmod +x install_nginx.sh && bash install_nginx.sh"]
  }

}