variable "extra_packages" {
  description = "The additional packages to install"
  type        = list(string)
  default     = ["openjdk-17-default-jvm", "python3", "pylint", "nodejs"]
}

module "accts" {
  source = "../../../tflib/accts"
  uid    = 65532
  gid    = 65532
  run-as = 65532
}

output "config" {
  value = jsonencode({
    contents = {
      packages = concat([
        // TODO: Add any other packages here that are *always* needed.
      ], var.extra_packages)
    }
    //
    accounts = module.accts.block
    entrypoint = {
      command = "/usr/bin/sonar-scanner-cli"
    }
  })
}
