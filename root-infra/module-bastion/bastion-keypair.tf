variable "ssh_public_key_path" {}

resource "aws_key_pair" "this" {
  key_name   = "key.${lower(var.project)}.${lower(var.company)}.io"
  public_key = "${file(var.ssh_public_key_path)}"
}

output "aws_key_pair_name" {
  value = "${aws_key_pair.this.key_name}"
}
