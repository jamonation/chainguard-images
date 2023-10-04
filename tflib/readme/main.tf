terraform {
  required_providers {
    docs = {
      source  = "chainguard-dev/images-readme"
      version = "0.0.1"
    }
  }
}

variable "image_name" { type = string }

data "docs_readme" "readme" {
  name = var.image_name
}

resource "local_file" "README" {
  content = templatefile("${path.module}/readme.tftpl", {
    name : data.docs_readme.readme.name,
    image : data.docs_readme.readme.image
    overview : data.docs_readme.readme.overview,
    body : data.docs_readme.readme.body,
  })
  filename = "${data.docs_readme.readme.image_path}/${data.docs_readme.readme.file_name}"
}
