locals {
  ssh_inventory_file_path = "${path.root}/../script-ssh/inventory.storage-baremetal"
}

resource "null_resource" "inventory-storage-baremetal-init" {
  triggers {
    # uuid = "${uuid()}" # for debug
    private_ips_zookeeper = "${join(",", aws_instance.zookeeper.*.private_ip)}"
    ssh_inventory_file_path = "${local.ssh_inventory_file_path}"
  }

  provisioner "local-exec" {
    command = <<EOT
    echo '\t(storage-baremetal)' > ${local.ssh_inventory_file_path}
EOT
  }

  depends_on = [
    "aws_instance.zookeeper",
  ]
}

resource "null_resource" "inventory-storage-baremetal-zookeeper" {
  count = "${aws_instance.zookeeper.count}"
  triggers {
    # uuid = "${uuid()}" # for debug
    private_ips_zookeeper = "${join(",", aws_instance.zookeeper.*.private_ip)}"
    ssh_inventory_file_path = "${local.ssh_inventory_file_path}"
  }

  provisioner "local-exec" {
    command = <<EOT
    echo 'zookeeper-${format("%02d", count.index + 1)}\t\t${element(aws_instance.zookeeper.*.private_ip, count.index)}' >> ${local.ssh_inventory_file_path}
EOT
  }

  depends_on = [
    "null_resource.inventory-storage-baremetal-init"
  ]
}

