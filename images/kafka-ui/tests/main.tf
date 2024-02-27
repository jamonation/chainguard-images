terraform {
  required_providers {
    oci = { source = "chainguard-dev/oci" }
  }
}

variable "digest" {
  description = "The image digest to run tests over."
}

data "oci_string" "ref" {
  input = var.digest
}

// Invoke a script with the test.
// $IMAGE_NAME is populated with the image name by digest.
// TODO: Update or remove this test as appropriate.
#data "oci_exec_test" "manifest" {
#  digest      = var.digest
#  script      = "./EXAMPLE_TEST.sh"
#  working_dir = path.module
#}

resource "random_pet" "suffix" {}

resource "helm_release" "kafka-ui" {
  name             = "kafka-ui-${random_pet.suffix.id}"
  namespace        = "kafka-ui-${random_pet.suffix.id}"
  repository       = "https://provectus.github.io/kafka-ui-charts"
  chart            = "kafka-ui"
  create_namespace = true

  values = [
    jsonencode({
      image = {
        repository = data.oci_string.ref.registry_repo
        tag        = data.oci_string.ref.pseudo_tag
      }
    })
  ]
}

module "helm_cleanup" {
  source    = "../../../tflib/helm-cleanup"
  name      = helm_release.kafka-ui.id
  namespace = helm_release.kafka-ui.namespace
}
