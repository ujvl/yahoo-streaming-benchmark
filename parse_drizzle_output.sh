#!/bin/bash

TMP_FILENAME="/tmp/parsed-results.txt"

# Extract relevant lines
cat $1 | awk -F ',' '{ if ($1 == "CampaignId") { out = 1 } if(out == 1) { print $0 } }' > $TMP_FILENAME

cat $TMP_FILENAME | awk -F',' '{if ($3 > 0){ res[$2] = res[$2] + $3; nu[$2] = nu[$2] + 1 }} END { for (r in res) { print r" "res[r]/nu[r]}}' | sort -n