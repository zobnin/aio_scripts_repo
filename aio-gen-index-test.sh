#!/bin/sh

set -eu

temp_index=$(mktemp)
trap 'rm -f "$temp_index"' EXIT HUP INT TERM

./aio-gen-index.sh > "$temp_index"
jq empty "$temp_index"

for apk_path in ./*.apk; do
    [ -f "$apk_path" ] || continue
    file=${apk_path#./}
    expected_sha256=$(sha256sum "$apk_path" | cut -d ' ' -f 1)

    jq -e \
        --arg file "$file" \
        --arg sha256 "$expected_sha256" \
        '[.[] | select(.file == $file)]
        | length == 1 and
          .[0].type == "widget" and
          .[0].package != "" and
          .[0].version != "" and
          .[0].versionCode > 0 and
          .[0].sha256 == $sha256' \
        "$temp_index" >/dev/null
done
