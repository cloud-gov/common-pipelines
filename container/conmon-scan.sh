#!/bin/bash

# Generates XML formatted report
grype image/image.tar -c common-pipelines/container/grype.yaml --only-fixed -q -o cyclonedx --file cves/output.xml
