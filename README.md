# Common Concourse Pipelines

Reusable Concourse pipelines. Reference the pipeline for your app's language, `fly set-pipeline`, and you're done.

## Usage

Set the `src-repo` value in your repository's Credhub path:

```sh
credhub set -n /path/to/repo/src-repo -v cloud-gov/your-repo
```

Run `credhub find -n src-repo` for examples.

Create file `ci/pipeline.yml` in your repository with the following contents, replacing LANGUAGE with your app's language:

```yaml
jobs:
- name: set-self
  plan:
    - get: common-pipelines
      trigger: true
    - set_pipeline: self
      file: common-pipelines/LANGUAGE/pipeline.yml

resources:
- name: common-pipelines
  type: git
  source:
    uri: https://github.com/cloud-gov/common-pipelines
    branch: main
    commit_verification_keys: ((cloud-gov-pgp-keys))
```

Commit and push the bootstrap pipeline for future use, and bootstrap the pipeline in Concourse:

```sh
fly -t ci set-pipeline --pipeline your-pipeline-name --config ci/pipeline.yml
```

Navigate to Concourse and un-pause the pipeline. The `bootstrap` job will run and replace itself with the common pipeline you specified. If the common pipeline is updated in the future, your pipeline will automatically pull in the changes.
