# OCI Pipeline

Build, audit, and scan Open Container Initiative (OCI) images on PR, and push them to a registry on merge if they pass all audits and scans.

## Usage

Copy an example from [examples](examples) into your repository.

* If you are building a repository in the `cloud-gov` GitHub organization, copy `cloud-gov-repo`.
  * Set the values in `ci/vars.yml` as needed. All values present in the example file are required.
  * Set `src-repo` to a value like `cloud-gov/your-repository` in CredHub.
* If you are building a repository in a different GitHub organization, copy `external-repo`.
  * Set `pipeline-config-repo` to a value like `cloud-gov/your-repository` in CredHub.
  * Set the values in `ci/vars.yml` as needed. All values present in the example file are required.

Once set, run:

```sh
fly -t ci set-pipeline --pipeline YOUR-PIPELINE-NAME --config ci/pipeline.yml --load-vars-from ci/vars.yml
```

It is recommended that your pipeline name, image name, and repository name all be identical so it is easy to locate them all.

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

Some vars in `your-repo/ci/vars/yml` may also be assigned empty lists:

```yaml
#vars.yml
dockerfile-path: []
```

Most often you will set the `dockerfile-path` to an empty list, unless you've created a Dockerfile for an external resource in this repo. If you do add a value to this list, you will most likely also want to set the `dockerfile-trigger` to `true` so the pipeline triggers on any Dockerfile changes.

Many params have reasonable defaults and don't need to be explicitly set. Test with your repository to find out.

Note that `vars.yml` cannot be empty; it must include maps, even empty ones, for every parameter specified in the pipeline, or the `set-self` job will fail because it cannot find the vars.

Since the vars file is in a GitHub repository, it cannot contain sensitive params. Storing the vars in CredHub would be better but is not currently possible; see "Design choices" below.

## Troubleshooting

See also [..README.md - Troubleshooting](../README.md#Troubleshooting).

### Failing to push

If the `put: image` step fails and the log shows the following:

```
retrying Post "https://aws-account-number.dkr.ecr.us-gov-west-1.amazonaws.com/v2/cloud-gov/example-pipeline/blobs/uploads/": EOF
```

Did you create the repository in ECR first? Did you set `image-repository` in CredHub to the name of the GitHub repository, excluding the GitHub organization?

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
