

// default values - these get overridden when the resource is called
variable "values" {
  type = any
  default = {
    fullnameOverride = "jenkins"

    nameOverride = "jenkins"
    controller = {
      javaOpts    = "-Djenkins.security.FIPS140.COMPLIANCE=true"
      jenkinsOpts = ""
      admin = {
        createSecret = false
      }
      installPlugins = false
      sidecars = {
        configAutoReload = {
          enabled = false
        }
      }
      image = {
        registry   = "cgr.dev"
        repository = "chainguard/jenkins"
        tag        = "latest"
      }
    }
  }
}

module "helm" {
  source = "../../../../tflib/imagetest/helm"

  namespace = "jenkins"
  chart     = "jenkins"
  repo      = "https://charts.jenkins.io"

  values = var.values
}

output "install_cmd" {
  value = module.helm.install_cmd
}

output "release_name" {
  value = module.helm.release_name
}
