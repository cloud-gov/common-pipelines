# OCI Pipeline

Build, audit, and scan Open Container Initiative (OCI) images on PR, and push them to a registry on merge if they pass all audits and scans.

## Usage

To setup a pipeline:

* Create a new folder (see note below on naming) in [ci/container](../ci/container).
  * If building an image from a cloud.gov owned repository, or from a repository that has been forked into the cloud.gov organization, create the folder in `ci/container/internal`.
  * If using an external organization's repository, then create the folder in `ci/container/external`.
* Copy the relevant example `vars.yml` file into your new folder.
  * Example file for [internal repos](examples/cloud-gov-repo/ci/vars.yml)
  * Example file for [external repos](examples/external-repo/ci/vars.yml)
* Set the values in the `vars.yml` file as needed. All values present in the example file are required.
* The `base-image` variable should be set to our [ubuntu-hardened-stig](https://github.com/cloud-gov/ubuntu-hardened) image.
* Some external repos require extra configuration. See the section below on [Configuring External Repositories](#configuring-external-repositories).
* Update the relevant list of repos in the [pipeline.yml](../ci/container/pipeline.yml) file with the name of your repo.
* Create a PR with your changes.

When the PR gets accepted and merged it will kick off the creation of a pipeline for building. auditing, and scanning your image.

**Note:** It is recommended that your folder name, image name, and repository name all be identical so it is easy to locate them all.

If problems occur, see [Troubleshooting](#Troubleshooting).

### Vars file

Some vars in `your-repo/ci/vars.yml` may be assigned empty maps:

```yaml
# vars.yml
oci-build-params: {}
```

You can populate the maps with params to pass to individual steps:

```yaml
# example: the oci-build step accepts a map named `oci-build-params`
# vars.yml
oci-build-params:
  CONTEXT: src # set OCI build context to a folder in the repository instead of the root
  DOCKERFILE: build/docker/Dockerfile # specify Dockerfile location when it is not in the repository root
```

Some vars in `your-repo/ci/vars.yml` may also be assigned empty lists:

```yaml
#vars.yml
dockerfile-path: []
```

Most often you will set the `dockerfile-path` to an empty list, unless you've created a Dockerfile for an external resource in this repo. If you do add a value to this list, you will most likely also want to set the `dockerfile-trigger` to `true` so the pipeline triggers on any Dockerfile changes.

Many params have reasonable defaults and don't need to be explicitly set. Test with your repository to find out.

Note that `vars.yml` cannot be empty; it must include maps, even empty ones, for every parameter specified in the pipeline, or the `set-self` job will fail because it cannot find the vars.

Since the vars file is in a GitHub repository, it cannot contain sensitive params. Storing the vars in CredHub would be better but is not currently possible; see "Design choices" below.

### Configuring External Repositories

In some cases external repositories may not work out-of-the-box with our base hardened image. The following methods can be used to address these cases:

1. Add a Dockerfile to the `common-pipelines` repository under `dockerfiles/<your-repo-name>`.
   * Copy over the contents of the external repo's Dockerfile and modify it so that it builds with our base hardened image.
   * Set the Dockerfile location in the relevant sections of the `vars.yml` file.
2. Fork the external repository to the cloud.gov organization.
   * Modify the Dockerfile to use the base hardened image and modify any other configurations necessary.
   * Proceed as you would for an internal repository.
3. Fork the external repository and add code to manually harden the image
   * This is only necessary for images that can't be made to work with our base hardened image

Adding a Dockerfile to the `common-pipelines` repo is preferred over forking a repo when possible, as this adds less maintenance burden.

### Configuring Pages Repositories

In some cases Pages repositories may need to be added so the pipelines can be added to the Pages team in Concourse CI.

1. Follow the above guidence for setting up the `vars.yml` and directory structure.
2. Add the repository named directory and `vars.yml` file under `ci/container/pages/<the-repo-name>`.
3. Add the repo name to the `set-pages-pipelines` task in the `ci/container/pipeline.yml`.

## STIG Rule Customization/Tailoring

We define the STIG rules that should be audited by the usg tool in the `tailor-stig.xml` file. If we were to make any modifications to this file we would document the changes in this readme.

## Troubleshooting

See also [..README.md - Troubleshooting](../README.md#Troubleshooting).

### Failing to push

If the `put: image` step fails and the log shows the following:

```
retrying Post "https://aws-account-number.dkr.ecr.us-gov-west-1.amazonaws.com/v2/cloud-gov/example-pipeline/blobs/uploads/": EOF
```

Did you create the ECR repository [in cg-provision](https://github.com/cloud-gov/cg-provision/tree/main/terraform/stacks/ecr) first? Did you set `image-repository` in CredHub to the name of the GitHub repository, excluding the GitHub organization?

## Design choices

### How are images tagged?

On merge, the `main` job pushes each image with the following tags:

* `latest` — a moving pointer to the most recently built image, configured on the `image` resource.
* `<config-digest>` — the full sha256 hex of the image **config** digest (the `sha256:` prefix stripped). The config digest is a content hash over the image's layers, environment, entrypoint, and labels, so it changes whenever any of those change. This makes the tag **guaranteed unique for any change to the image**, while identical rebuilds reuse the same tag rather than creating a redundant one. This is the tag to use when you need to pin an exact, immutable build.
* `<short_ref>-<short_config-digest>` — a human-readable tag combining the commit short hash (the first seven characters of the commit SHA) with the first twelve characters of the config digest. It carries traceability back to the commit the image was built from while being practically unique per build. This replaces the previous standalone `<short_ref>` tag, which was not unique per build (a `base-image` bump, the weekly rebuild, or `common-dockerfiles` changes rebuild the same commit and would overwrite it).

These tags are assembled by the [`generate-tags`](generate-tags.sh) task, which reads `src/.git/short_ref` and the `image/digest` file produced by the `oci-build` task, and writes a whitespace-separated list to `tags/additional_tags`. That file is fed to the `registry-image` resource's `additional_tags` param on the `put: image` step.

The `staging` job pushes each image to the `staging-image` resource (the `staging` tag) using the same `generate-tags` task, but with `tag_prefix: staging-` so the unique tags become `staging-<config-digest>` and `staging-<short_ref>-<short_config-digest>`. The prefix keeps staging artifacts clearly distinguishable in the registry from the promoted tags pushed by the `main` job.

The `generate-tags` task takes a `TAG_PREFIX` param that must match the resource's `tag_prefix` (empty for `main`, `staging-` for `staging`). It uses this only to validate that the final pushed tag stays within the 128-character OCI/ECR tag limit, failing closed if a tag would be too long. With the current `sha256` config digests the longest tag is `staging-` + 64 hex = 72 characters, well within the limit; the guard protects against a future change (e.g. a longer digest algorithm) silently producing an invalid tag.

Note: the config digest is **not** the same value as the registry *manifest* digest (the `repo@sha256:...` that `docker pull` reports). We tag with the config digest because `oci-build` already emits it as `image/digest` with no extra registry round-trip, and it is equally unique per build for our purpose of "a new tag whenever the image changes." If a tag matching the registry manifest digest is ever required, it would need to be computed from the image tarball (or read back from the resource's push output) instead.

We build a variety of docker images with a variety of versioning schemes, ranging from "none" to semantic versioning. Semantic version tags are intentionally *not* generated automatically: most of these images have no meaningful version to bump, and SemVer encodes a human judgment about API compatibility that a trigger-driven rebuild cannot make. For the subset of images whose upstream publishes real release tags, deriving a version tag from that upstream reference (via `registry-image`'s `version` / `bump_aliases`) remains a possible future opt-in.

### Why load step params from a map instead of individually?

The current approach groups task parameters into a map (see [Usage](#Usage)) and sets the entire map "structurally" on the task at once. An alternative approach would be eliding the map and specifying each parameter in the vars file or CredHub separately, like:

```yaml
# vars.yml
CONTEXT: src
DOCKERFILE: Dockerfile
```

However, using that approach, every single parameter that might be used by _any_ consumer of the pipeline must be surfaced up-front and be specified in `vars.yml` by _every_ consumer of the pipeline, even if you want to omit a parameter so you take the task default. This requires more up-front work for users of the pipeline and makes it impossible to simplify configuration by accepting the task's default param value.

In other words, this approach results in the smallest API surface and least implementation burden for consumers of the pipeline.

### Why load step params from a vars file in your repository instead of CredHub?

Vars in CredHub of type `json` are not [structurally substituted](https://concourse-ci.org/vars.html#var-interpolation) like vars in a local yaml (or JSON!) file. Without structural substitution, you'd need to set each value individually; see the previous section for why this would create more work. (Issue or discussion on Concourse repo forthcoming.)

### Why have separate pipelines for GitHub repos inside and outside the cloud-gov org?

Building images from repositories we do not control has different requirements:

* Building pull requests is not desirable because we cannot provide automated feedback on those PRs like we can for PRs in our own GitHub org
* Commits for external repositories cannot be verified, but commits for cloud-gov repositories *must* be verified, and it would be difficult or impossible to configure the `src` resource conditionally based on GitHub org
* When building internal repositories, the pipeline configuration (pipeline.yml and vars.yml) are in the same repository (src) as the Dockerfile and source code. When building an external repository, this is not the case; we need separate Concourse resources for the source repository and our pipeline configuration.

To accommodate these differences, we maintain two different pipeline files.
