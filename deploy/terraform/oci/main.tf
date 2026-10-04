# Lab host on Oracle Cloud Infrastructure (cloud target): one Ubuntu 22.04 instance in a VCN of
# its own, reached only over SSH from allowed_cidr. cloud-init (OCI reads the user_data metadata
# key) fetches the lab and runs deploy/ansible/site.yml, the same bootstrap as the other clouds.
# Lab services live on the Docker network inside the VM; only SSH is open.
#
# Credentials: an OCI API signing key. The provider reads ~/.oci/config (DEFAULT profile), which
# the player sets up with `oci setup config` or from the console, so no secret is passed here.
# region and compartment come from vars.
#
# Auto-stop note: cloud-init powers the instance off after auto_stop_hours, but OCI keeps billing
# a stopped instance's resources until it is TERMINATED. The launcher's timed `terraform destroy`
# (and Stop) removes everything and is the reliable way to end billing.

terraform {
  required_version = ">= 1.6"
  # The launcher keeps state outside the lab folder: -backend-config=path=...
  backend "local" {}
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
  }
}

# Reads ~/.oci/config (DEFAULT profile) for API-key auth; region comes from the var.
provider "oci" {
  region = var.region
}

# A short random id per deployment, stable across re-applies, so two deployments of the same lab
# never collide on names.
resource "terraform_data" "deployment" {
  input = substr(replace(uuid(), "-", ""), 0, 8)
  lifecycle {
    ignore_changes = [input]
  }
}

locals {
  name = "cyberctf-${var.lab_slug}-${terraform_data.deployment.output}"
  # Sizing the lab asks for in .ctf/metadata.json ("resources"), when the lab ships it.
  resources = try(jsondecode(file("${path.module}/../../../.ctf/metadata.json")).resources, {})
  memory_mb = try(local.resources.memory_mb, 4096)
  ocpus     = local.memory_mb <= 4096 ? 1 : local.memory_mb <= 8192 ? 2 : 4
  memory_gb = ceil(local.memory_mb / 1024)
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

# Canonical Ubuntu 22.04 image for this shape in this region (OCI image OCIDs are region-specific).
data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = var.instance_type
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_vcn" "lab" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = ["10.42.0.0/16"]
  display_name   = local.name
}

resource "oci_core_internet_gateway" "lab" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.lab.id
  display_name   = local.name
}

resource "oci_core_route_table" "lab" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.lab.id
  display_name   = local.name
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.lab.id
  }
}

# Only SSH, only from the player; egress open so the lab can fetch its images.
resource "oci_core_security_list" "lab" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.lab.id
  display_name   = local.name

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
  dynamic "ingress_security_rules" {
    for_each = var.allowed_cidr == "" ? [] : [var.allowed_cidr]
    content {
      protocol = "6" # TCP
      source   = ingress_security_rules.value
      tcp_options {
        min = 22
        max = 22
      }
    }
  }
}

resource "oci_core_subnet" "lab" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.lab.id
  cidr_block        = "10.42.1.0/24"
  display_name      = local.name
  route_table_id    = oci_core_route_table.lab.id
  security_list_ids = [oci_core_security_list.lab.id]
}

resource "oci_core_instance" "labhost" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = local.name
  shape               = var.instance_type

  shape_config {
    ocpus         = local.ocpus
    memory_in_gbs = local.memory_gb
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.lab.id
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/../../cloud-init/user-data.yaml.tftpl", {
      lab_repository    = var.lab_repository
      lab_commit        = var.lab_commit
      ctf_api_url       = var.ctf_api_url
      ctf_launch_token  = var.ctf_launch_token
      attackbox_image   = var.attackbox_image
      ssh_public_key    = var.ssh_public_key
      auto_stop_minutes = var.auto_stop_hours * 60
    }))
  }
}
