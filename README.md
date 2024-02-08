# Common Concourse Pipelines

Reusable Concourse pipelines. Reference the pipeline for your app's language, `fly set-pipeline`, and you're done.

## Index 

* `ci`: Concrete pipeline instances that use templates from this repository.
* `container`: Template pipelines for containerized software.
* `go`: Template pipeline for Go apps. Not currently in use.

## Usage

See the README in each folder for pipeline-specific details. In general, you will "register" a new pipeline by modifying a parent pipeline in `ci/` and configuring it with a vars file. Once you merge your changes to `main`, the parent pipeline will automatically create your new child pipeline.

## Motivation

An adage of Continuous Integration: "Treat pipelines like cattle, not like pets."

cloud.gov maintains a variety of software written in a handful of programming languages. Apps written in the same language should be built and deployed in the same way, and developers should not have to reinvent the wheel by writing a new pipeline every time.

## Architecture

Common pipelines use a parent/child pattern so that one pipeline can manage many others. For example, this diagram shows the relationships between container pipelines:

```mermaid
flowchart LR
    classDef ellipses fill:#ffffff,stroke:#ffffff
    classDef job fill:#ecffec,stroke:#73d893

    subgraph Main Concourse Team
        container["container pipeline"]
        container -->|sets self| container
        container -->|contains| external["set-external-pipelines job"]:::job
        container -->|contains| internal["set-internal-pipelines job"]:::job
        container -->|contains| pages["set-pages-pipelines job"]:::job

        external -->|sets| cf-cli-resource["cf-cli-resource pipeline"]
        external -->|sets| cf-resource["cf-resource pipeline"]
        external -->|sets| external-etc["..."]:::ellipses
        external -->|sets| time-resource["time-resource pipeline"]
        internal -->|sets| cron-resource["cron-resource pipeline"]
        internal -->|sets| general-task["general-task pipeline"]
        internal -->|sets| internal-etc["..."]:::ellipses
        internal -->|sets| s3-resource["s3-resource pipeline"]
    end
    
    subgraph Pages Concourse Team
        pages -->|sets| pages-dind-v25["image-dind-v25 pipeline"]
        pages -->|sets| pages-node-v20["image-node-v20 pipeline"]
        pages -->|sets| pages-python-v3["image-python-v3.11 pipeline"]
        pages -->|sets| pages-etc["..."]:::ellipses
    end
```

This has several advantages over individually set pipelines:

* Operators only need to manually fly one pipeline, for example `container`, instead of many individual pipelines, making recovery in case of system error easier.
* The single top-level pipeline can use Concourse steps like `across` to set each child pipeline in the exact same way, with any differences extracted as `vars`. This brings all the benefits of DRY to pipelines.

## Design principles

* Developers should be able to adopt common pipelines with a minimum of effort. One line of code would be ideal.
* The configuration options for each pipeline should be minimal. They're the API of the pipelines; keep it simple.
* Favor convention over configuration. Repositories using common pipelines should "just work" if their folders and files are in the right place.

## Development

If you want to iterate on a pipeline in this repository, consider pushing your changes to a topic branch. Topic branches do not have merge protection, so you will be able to iterate more quickly without getting pull requests approved. Change your `pipeline.yml` in your downstream repository to reference your topic branch instead of `main` in the `common-pipelines` resource to continuously pull in your changes. (You can consider working on a topic branch in your downstream repo as well.)

## Troubleshooting

### Pipeline archived after bootstrap

If your pipeline shows up as "Archived" in Concourse after running the steps in [Usage](#Usage), the cause could be one of the following:

* A branch is wrong. If you are using a topic branch to work on a pipeline, double-check that you updated all references from `main` to the topic branch. See [Development](#Development). You may need to run `fly destroy-pipeline` to remove the archived pipeline before you can `set` it again.
* An input name may be wrong. Check the logs of any `set_pipeline` steps for errors.

### Old pipeline version

After bootstrapping, Concourse will sometimes update a pipeline using outdated (possibly cached) resources. Destroy the pipeline, wait a moment, and try again.
