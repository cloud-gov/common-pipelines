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
* The `base-image` variable should be set to our [ubuntu-hardened](https://github.com/cloud-gov/ubuntu-hardened) image.
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

## CIS Rule Customization/Tailoring

We set the following CIS Rule exceptions in our `tailor.xml` file:

| Rule | Name | Reason for Exception | How to Confirm |
| ---- | ---- | -------------------- | -------------- |
| 1.4.3 | `xccdf_org.ssgproject.content_rule_ensure_root_password_configured` | Not applicable to concourse containers | Check out documentation on [concourse internals](https://concourse-ci.org/internals.html) and [fly intercept](https://concourse-ci.org/builds.html#fly-intercept) |
| 3.5.2.9 | `xccdf_org.ssgproject.content_rule_service_nftables_enabled` | False Positive: nftables is enabled | Run `systemctl is-enabled nftables` |
| 3.5.2.8 | `xccdf_org.ssgproject.content_rule_nftables_ensure_default_deny_policy` | Not applicable to containers, needs privileged access | Run any nftables command, like `nft list ruleset` to see that the operation is not permitted |
| 3.5.2.10 | `xccdf_org.ssgproject.content_rule_nftables_rules_permanent`| Not applicable to containers, needs privileged access | Run any nftables command, like `nft list ruleset` to see that the operation is not permitted |
| 3.5.2.5 | `xccdf_org.ssgproject.content_rule_set_nftables_base_chain` | Not applicable to containers, needs privileged access | Run any nftables command, like `nft list ruleset` to see that the operation is not permitted |
| 3.5.2.6 | `xccdf_org.ssgproject.content_rule_set_nftables_loopback_traffic` | Not applicable to containers, needs privileged access | Run any nftables command, like `nft list ruleset` to see that the operation is not permitted |
| 3.5.2.4 | `xccdf_org.ssgproject.content_rule_set_nftables_table` | Not applicable to containers, needs privileged access | Run any nftables command, like `nft list ruleset` to see that the operation is not permitted |
| 4.2.3 | `xccdf_org.ssgproject.content_rule_permissions_local_var_log` | Triggers on apt log files causing a false positive | Apt log permissions are set this way [by design](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=285551)

## Troubleshooting

See also [..README.md - Troubleshooting](../README.md#Troubleshooting).

### Failing to push

If the `put: image` step fails and the log shows the following:

```
retrying Post "https://aws-account-number.dkr.ecr.us-gov-west-1.amazonaws.com/v2/cloud-gov/example-pipeline/blobs/uploads/": EOF
```

Did you create the ECR repository [in cg-provision](https://github.com/cloud-gov/cg-provision/tree/main/terraform/stacks/ecr) first? Did you set `image-repository` in CredHub to the name of the GitHub repository, excluding the GitHub organization?

## Design choices

### Why tag with the git short hash / short_ref?

We build a variety of docker images with a variety of versioning schemes, ranging from "none" to semantic versioning. We may expand our tagging scheme in the future, but for now, the short hash — the first seven characters of the commit SHA — is a tag that works universally and functions as a reference back to the commit the image was built from, which is useful in troubleshooting.

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
