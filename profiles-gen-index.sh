#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

output="aioprofiles.index"
tmp="$(mktemp)"

# Start the JSON array
echo '[' > "$tmp"
first=true

for zip in *.zip; do
  # Check if the archive contains aio-profile-meta.json
  if unzip -l "$zip" 2>/dev/null | grep -q 'aio-profile-meta.json'; then
    # Calculate the MD5 checksum of the ZIP
    md5=$(md5sum "$zip" | awk '{print $1}')
    # Extract the contents of the meta file
    meta_json=$(unzip -p "$zip" aio-profile-meta.json)

    # Build the JSON object: add "file" and "md5sum" fields
    obj=$(printf '%s' "$meta_json" \
      | jq --arg file "$zip" --arg md5sum "$md5" '. + {file: $file, md5sum: $md5sum}')

    # If this isn't the first entry, prepend a comma
    if ! $first; then
      echo ',' >> "$tmp"
    else
      first=false
    fi

    # Append the object to the temp file
    echo "$obj" >> "$tmp"
  else
    echo "Skipping '$zip' — aio-profile-meta.json not found" >&2
  fi
done

# Close the JSON array and move it to the final output
echo ']' >> "$tmp"
mv "$tmp" "$output"

echo "Done: $output"

