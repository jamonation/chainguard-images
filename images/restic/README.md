<!--monopod:start-->
# restic
| | |
| - | - |
| **Status** | stable |
| **OCI Reference** | `cgr.dev/chainguard/restic` |


* [View Image in Chainguard Academy](https://edu.chainguard.dev/chainguard/chainguard-images/reference/restic/overview/)
* [View Image Catalog](https://console.enforce.dev/images/catalog) for a full list of available tags.
*[Contact Chainguard](https://www.chainguard.dev/chainguard-images) for enterprise support, SLAs, and access to older tags.*

---
<!--monopod:end-->

Minimal image with Restic.

## Get It!

The image is available on `cgr.dev`:

```
docker pull cgr.dev/chainguard/restic:latest
```

## Using Restic

This image contains a standalone `restic` binary. To use it, run a container with a volume mounted at the path where you would like to create your backup repository, and mount any other path(s) that you would like to back up into the running container.

For example, to use a volume called `backup-repo`, create it and set permissions for the restic user to access it with the following command:

```
docker run --rm -v backup-repo:/repo -it cgr.dev/chainguard/bash "chown 65532:65532 /repo"
```

Then mount the volume and initialize your backup repository like this, substituting in a command for a password (or use one of restic's other password options like a file or environment variable):

```
docker run --rm \
  -v backup-repo:/repo \
  cgr.dev/chainguard/restic \
    --password-command "..." \
    -r /repo \
    init
```

Now you can create backups by mounting the directories and files that you want backed up as volumes to expose the files to restic.
