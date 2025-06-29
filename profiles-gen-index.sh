#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

output="aioprofiles.json"
tmp="$(mktemp)"

# Start the JSON array
printf '[\n' > "$tmp"
first=true

for zip in *.zip; do
  # Find the first file inside the ZIP matching *.profile
  profile_file=$(unzip -Z1 "$zip" '*.profile' 2>/dev/null | head -n1)

  if [[ -n "$profile_file" ]]; then
    # Calculate the MD5 checksum of the ZIP
    md5=$(md5sum "$zip" | awk '{print $1}')
    # Extract the JSON metadata
    meta_json=$(unzip -p "$zip" "$profile_file")

    # Parse individual fields
    name=$(jq -r '.name' <<< "$meta_json")
    description=$(jq -r '.description' <<< "$meta_json")
    author=$(jq -r '.author' <<< "$meta_json")
    version=$(jq -r '.version' <<< "$meta_json")

    # Separator between objects
    if ! $first; then
      printf ',\n' >> "$tmp"
    else
      first=false
    fi

    # Manually assemble the JSON object
    {
      printf '{\n'
      printf ' "file": "%s",\n'        "$zip"
      printf ' "name": "%s",\n'        "$name"
      printf ' "description": "%s",\n' "$description"
      printf ' "author": "%s",\n'      "$author"
      printf ' "version": "%s",\n'     "$version"
      printf ' "md5sum": "%s"\n'       "$md5"
      printf '}'
    } >> "$tmp"
  else
    echo "Skipping '$zip' — no .profile file found" >&2
  fi
done

# Close the JSON array
printf '\n]\n' >> "$tmp"

# Finalize
mv "$tmp" "$output"
echo "Done: $output"

