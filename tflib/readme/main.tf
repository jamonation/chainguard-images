terraform {
  required_providers {
    docs = {
      source  = "chainguard-dev/images-readme"
      version = "0.0.1"
    }
  }
}

variable "image_name" { type = string }

data "docs_readme" "all" {
  name = var.image_name
}

resource "local_file" "README" {
  content = templatefile("${path.module}/readme.tftpl", {
    name : data.docs_readme.all.name,
    image : data.docs_readme.all.image
    intro : data.docs_readme.all.intro,
    description : data.docs_readme.all.description,
    body : data.docs_readme.all.body,
  })
  filename = "images/${var.image_name}/README.md"
}
