#!/bin/sh

set -e

for file in $(find lib -name '*.pl' -o -name '*.pm' | sort); do
  echo "$file"
  carmel exec perltidy "$file"
done
