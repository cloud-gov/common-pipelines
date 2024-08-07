#!/bin/bash
grype image/image.tar -c common-pipelines/container/grype.yaml --only-fixed -q -o json --file cves/output.json
grype image/image.tar -c common-pipelines/container/grype.yaml  --only-fixed -q -o table --file table.txt

cat cves/output.json | jq '.matches | .[]? |  .vulnerability.severity' >> severity.txt

critical=$(grep -o -i critical severity.txt | wc -l)
high=$(grep -o -i high severity.txt | wc -l)
medium=$(grep -o -i medium severity.txt | wc -l)
low=$(grep -o -i low severity.txt | wc -l)
negligible=$(grep -o -i negligible severity.txt | wc -l)

echo "Critical: $critical"
echo "High: $high"
echo "Medium: $medium"
echo "Low: $low"
echo "Negligible: $negligible"

cat table.txt
