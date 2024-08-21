#!/bin/bash

# Send POST request containing grype results to Defect Dojo

curl -X "POST" $DEFECTDOJO_IMPORT_URL \
  -H "accept: application/json" \
  -H "Content-Type: multipart/form-data" \
  -H "Authorization: Token $DEFECTDOJO_AUTH_TOKEN" \
  -F "product_type_name=Container Image" \
  -F "active=true" \
  -F "minimum_severity=Info" \
  -F "verified=true" \
  -F "scan_type=Anchore Grype" \
  -F "product_name=$IMAGENAME" \
  -F "engagement_name=CVE Scan $(date '+%Y-%m-%d')" \
  -F "engagement_end_date=$(date '+%Y-%m-%d')" \
  -F "auto_create_context=true" \
  -F "close_old_findings=true" \
  -F "close_old_findings_product_scope=true" \
  -F "file=@cves/output.json;type=application/json"
