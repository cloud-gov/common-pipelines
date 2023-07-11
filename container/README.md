# OCI Pipeline

Build, audit, and scan Open Container Initiative (OCI) images on PR, and push them to a registry on merge if they pass all audits and scans.

## Usage

In addition to setting `src-repo` in CredHub (see [the repository README](../README.md#Usage)), you must copy `vars.yml` to `ci/vars.yml` in your repository. The vars in the file may be assigned empty maps:

```yaml
# vars.yml
oci-build-params: {}
```

Or you can populate the maps with params to pass to individual steps:

```yaml
# example: the oci-build step accepts a map named `oci-build-params`
# vars.yml
oci-build-params:
  CONTEXT: src # set OCI build context to a folder in the repository instead of the root
  DOCKERFILE: build/docker/Dockerfile # specify Dockerfile location when it is not in the repository root
```

Most params have reasonable defaults and don't need to be explicitly set. Test with your repository to find out.

Note that `vars.yml` cannot be empty; it must include maps, even empty ones, for every parameter specified in the pipeline, or the `set-self` job will fail because it cannot find the vars.

Since the vars file is in a GitHub repository, it cannot contain sensitive params. Storing the vars in CredHub would be better but is not currently possible; see "Design choices" below.

## Design choices

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
