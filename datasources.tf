# Random string
resource "random_string" "deploy_id" {
  length  = 5
  special = false
  upper   = false
  number  = false
}

data "template_cloudinit_config" "appdbsrv" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content      = data.template_file.appdbsrv_cloud_init.rendered
  }
}
data "template_file" "appdbsrv_cloud_init" {
  template = file("${path.module}/scripts/appdbsrv-cloud-config.template.yaml")

  vars = {
    bootstrap_root_sh_content = base64gzip(data.template_file.bootstrap_root.rendered)
    # bootstrap_ubuntu_sh_content = base64gzip(data.template_file.bootstrap_ubuntu.rendered)
    stack_info_content = base64gzip(data.template_file.stack_info.rendered)
    # install_Fn4_sh_content      = base64gzip(data.template_file.install_Fn4.rendered)
    # inject_pub_keys_sh_content  = base64gzip(data.template_file.inject_pub_keys.rendered)
    # install_nginx_sh_content    = base64gzip(data.template_file.install_nginx.rendered)
  }
}

data "template_cloudinit_config" "bastion" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content      = data.template_file.bastion_cloud_init.rendered
  }
}
data "template_file" "bastion_cloud_init" {
  template = file("${path.module}/scripts/bastion-cloud-config.template.yaml")

  vars = {
    # inject_pub_keys_sh_content = base64gzip(data.template_file.inject_pub_keys.rendered)
  }
}

data "template_file" "bootstrap_root" {
  template = file("${path.module}/scripts/bootstrap_root.sh")
}
data "template_file" "bootstrap_ubuntu" {
  template = file("${path.module}/scripts/bootstrap_ubuntu.sh")

  # Variables parsed into bootstrap_ubuntu.sh as it is encoded in to Cloud-Init
  vars = {
    deployment_id = local.Fn4_deploy_id
    tenancy_id    = var.tenancy_ocid
  }
}

data "template_file" "stack_info" {
  template = file("${path.module}/scripts/stack_info.json")

  # Variables parsed into stack_info.json as it is encoded in to Cloud-Init
  vars = {
    deployment_id  = local.Fn4_deploy_id
    compartment_id = local.Fn4_cid
    tenancy_id     = var.tenancy_ocid
    # load_balancer_id   = local.Fn4_lb_id
    # Fn4_url            = local.Fn4_lb_url
    priv_subnet_id = local.Privsn001_id
    ad             = local.Fn4_ad
  }
}

data "template_file" "install_Fn4" {
  template = file("${path.module}/scripts/install_Fn4.sh")

  vars = {
    Fn4_gitrepo_secret_id = local.Fn4_gitrepo_secret_id
  }
}

data "template_file" "inject_pub_keys" {
  template = file("${path.module}/scripts/inject_pub_keys.sh")
}

data "template_file" "install_nginx" {
  template = file("${path.module}/scripts/install_nginx.sh")

  vars = {
    install_certs            = var.install_certs
    Fn4dev_ml_ssl_secret_id  = local.Fn4dev_ml_ssl_secret_id
    Fn4dev_ml_priv_secret_id = local.Fn4dev_ml_priv_secret_id
    Fn4_env_name             = local.Fn4_env_name
  }
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

resource "random_shuffle" "compute_ad" {
  input        = data.oci_identity_availability_domains.ads.availability_domains[*].name
  result_count = length(data.oci_identity_availability_domains.ads.availability_domains[*].name)
}

locals {
  ad_random = random_shuffle.compute_ad.result[0]
  Fn4_ad    = var.randomise_ad ? local.ad_random : var.ad
}
