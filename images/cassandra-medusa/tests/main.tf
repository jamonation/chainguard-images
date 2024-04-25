terraform {
  required_providers {
    oci       = { source = "chainguard-dev/oci" }
    imagetest = { source = "chainguard-dev/imagetest" }
  }
}

variable "digest" {
  description = "The image digest to run tests over."
}

data "oci_string" "ref" { input = var.digest }

data "imagetest_inventory" "this" {}

module "helm_k8ssandra_operator" {
  source    = "../../../tflib/imagetest/helm"
  chart     = "k8ssandra-operator"
  repo      = "https://helm.k8ssandra.io/stable"
  namespace = "k8ssandra-operator"

  values = {
    create_namespace = "true"
    image = {
      registry   = "cgr.dev"
      repository = "chainguard/k8ssandra-operator"
      tag        = "latest"
    }
  }
}

module "helm_cert_manager" {
  source    = "../../../tflib/imagetest/helm"
  chart     = "cert-manager"
  repo      = "https://charts.jetstack.io"
  namespace = "cert-manager"

  values = {
    create_namespace  = "true"
    namespaceOverride = "cert-manager"
    name              = "cert-manager"
    image = {
      repository = "cgr.dev/chainguard/cert-manager-controller"
      tag        = "latest"
    }
    cainjector = {
      image = {
        repository = "cgr.dev/chainguard/cert-manager-cainjector"
        tag        = "latest"
      }
    }
    acmesolver = {
      image = {
        repository = "cgr.dev/chainguard/cert-manager-acmesolver"
        tag        = "latest"
      }
    }
    webhook = {
      image = {
        repository = "cgr.dev/chainguard/cert-manager-webhook"
        tag        = "latest"
      }
    }
    installCRDs = true
  }
}

resource "imagetest_harness_k3s" "this" {
  name      = "cassandra-medusa"
  inventory = data.imagetest_inventory.this

  sandbox = {
    mounts = [
      {
        source      = path.module
        destination = "/tests"
      }
    ]
    envs = {
      "NAMESPACE"        = "k8s-medusa"
      "NAME"             = "medusa"
      "IMAGE_REGISTRY"   = data.oci_string.ref.registry
      "IMAGE_REPOSITORY" = split("/", data.oci_string.ref.repo)[0]
      "IMAGE_TAG"        = data.oci_string.ref.pseudo_tag
    }
  }
}

resource "imagetest_feature" "basic" {
  harness     = imagetest_harness_k3s.this
  name        = "Basic"
  description = "Basic functionality of the cert-manager helm chart."

  steps = [
    {
      name = "setup cert manager"
      cmd  = module.helm_cert_manager.install_cmd
    },
    {
      name = "setup k8ssandra operator"
      cmd  = module.helm_k8ssandra_operator.install_cmd
    },
    {
      name = "minio install"
      cmd  = "/tests/minio-install.sh"
    },
    {
      name = "Test"
      cmd  = "/tests/medusa-install.sh"
    },
  ]

  labels = {
    type = "k8s"
  }
}
