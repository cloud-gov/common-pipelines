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

## Motivation

An adage of Continuous Integration: "Treat pipelines like cattle, not like pets."

cloud.gov maintains a variety of software written in a handful of programming languages. Apps written in the same language should be built and deployed in the same way, and developers should not have to reinvent the wheel by writing a new pipeline every time.

## Design principles

* Developers should be able to adopt common pipelines into their pipeline with a minimum of effort. Zero or one lines of code would be ideal.
* The configuration options for each pipeline should be minimal. They're the API of the pipelines; keep it simple.
* Favor convention over configuration. Repositories using common pipelines should "just work" if their folders and files are in the right place.

## Development

If you want to iterate on a pipeline in this repository, consider pushing your changes to a topic branch. Topic branches do not have merge protection, so you will be able to iterate more quickly without getting pull requests approved. Change your `pipeline.yml` in your downstream repository to reference your topic branch instead of `main` in the `common-pipelines` resource to continuously pull in your changes. (You can consider working on a topic branch in your downstream repo as well.)
