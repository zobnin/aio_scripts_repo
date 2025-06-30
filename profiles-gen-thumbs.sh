#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

IMAGEMAGICK_CMD=magick

rm -f aioprofiles.thumb

declare -a thumbs

for zipfile in *-aio-profile.zip; do
  base="${zipfile%.zip}"
  for img in "${base}"_*.webp; do
    [ -f "$img" ] || continue
    thumb="${img%.webp}_thumb.webp"

    "$IMAGEMAGICK_CMD" "$img" \
      -resize 150x150^ \
      -gravity center \
      -extent 150x150 \
      "$thumb"

    thumbs+=("$thumb")
  done
done

if (( ${#thumbs[@]} > 0 )); then
  echo "Archiving ${#thumbs[@]} thumbnails into aioprofiles.thumbs…"
  zip -j aioprofiles.thumbs "${thumbs[@]}"
  echo "Done"
  rm -rf *thumb.webp
else
  echo "No *_thumb.webp."
fi

