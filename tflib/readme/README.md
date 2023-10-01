# Overview 

This module will render a README.md file for an image based on a README.hcl file that contains variables for each section in a readme. The intent is to create a reusable, structured template for readmes.

A README.hcl file should live in an image's directory and contain the following variables:

1. image
2. intro
3. body
4. description

## Using

*Note*: these instructions will use an image name of `postgresql` as an example.

1. To generate a readme, add this module to the `images/postgresql/main.tf` file:

```
module "readme" {
  source     = "../../tflib/readme"
  image_name = basename(path.module)
}
```

2. Next, run `terraform plan`. It will generate an error, but will also create a /tmp/README.hcl template that you can use for your image.

3. Copy the /tmp/README.hcl file into `images/postgresql/README.hcl`.

4. Edit `images/postgresql/README.hcl`. Each field is required and will be rendered as Markdown in the generate README.md. Substitute quotes with <<EOSOMETHING heredoc delimiters for multi-line blocks if you would like to add longer blocks of Markdown within a section.

5. Run the `terraform plan` command again and inspect the content that will be rendered to `images/postgresql/README.md`.

6. Edit your `README.hcl`, `terraform plan`, and once you are happy with the proposed `README.md`, apply your changes.

7. Commit the generated `README.md` to git.
