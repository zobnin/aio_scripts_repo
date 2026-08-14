#!/bin/sh

set -eu

# Generates index entries for Lua scripts and APK plugins.
#
# APK package name, version and application label are read from the APK with
# Android's aapt2 tool. All APK files are indexed as widget plugins; their
# search capability is an implementation detail and does not change the entry
# type used by AIO Store.

export LC_ALL=C

find_aapt_tool() {
    if [ -n "${AAPT2:-}" ] && [ -x "$AAPT2" ]; then
        printf '%s\n' "$AAPT2"
        return
    fi

    if command -v aapt2 >/dev/null 2>&1; then
        command -v aapt2
        return
    fi

    for sdk_dir in "${ANDROID_SDK_ROOT:-}" "${ANDROID_HOME:-}" "${HOME:-}/Android/Sdk"; do
        [ -n "$sdk_dir" ] || continue
        [ -d "$sdk_dir/build-tools" ] || continue

        aapt_tool=$(find "$sdk_dir/build-tools" -mindepth 2 -maxdepth 2 \
            -type f -name aapt2 -perm -u+x | sort -V | tail -n 1)
        if [ -n "$aapt_tool" ]; then
            printf '%s\n' "$aapt_tool"
            return
        fi
    done

    if [ -n "${AAPT:-}" ] && [ -x "$AAPT" ]; then
        printf '%s\n' "$AAPT"
        return
    fi

    if command -v aapt >/dev/null 2>&1; then
        command -v aapt
        return
    fi

    return 1
}

json_string() {
    jq -Rn --arg value "$1" '$value'
}

write_lua_entry() {
    lua_path=$1
    file=${lua_path#./}
    output_path=$2

    {
        printf '{\n "file": %s,\n' "$(json_string "$file")"
        tr -d '\r' < "$lua_path" \
            | sed -nE 's/^--[[:space:]]*([a-zA-Z]+)[[:space:]]*=[[:space:]]*(.*)$/ "\1": \2,/p'
        printf ' "md5sum": %s\n}\n' "$(json_string "$(md5sum "$lua_path" | cut -d ' ' -f 1)")"
    } | jq . > "$output_path"
}

write_apk_entry() {
    apk_path=$1
    file=${apk_path#./}
    output_path=$2
    aapt_tool=$3

    badging=$("$aapt_tool" dump badging "$apk_path")
    package_name=$(printf '%s\n' "$badging" \
        | sed -n "s/^package: name='\([^']*\)'.*/\1/p" \
        | head -n 1)
    version_name=$(printf '%s\n' "$badging" \
        | sed -n "s/^package: .* versionName='\([^']*\)'.*/\1/p" \
        | head -n 1)
    app_name=$(printf '%s\n' "$badging" \
        | sed -n "s/^application-label:'\([^']*\)'/\1/p" \
        | head -n 1)

    if [ -z "$package_name" ] || [ -z "$version_name" ]; then
        printf 'Unable to read package or version from %s with %s\n' \
            "$file" "$aapt_tool" >&2
        exit 1
    fi

    [ -n "$app_name" ] || app_name=$package_name

    jq -n \
        --arg file "$file" \
        --arg name "$app_name" \
        --arg package "$package_name" \
        --arg version "$version_name" \
        --arg md5sum "$(md5sum "$apk_path" | cut -d ' ' -f 1)" \
        '{
            file: $file,
            name: $name,
            type: "widget",
            package: $package,
            version: $version,
            md5sum: $md5sum
        }' > "$output_path"
}

command -v jq >/dev/null 2>&1 || {
    echo 'jq is required to generate aiorepo.index' >&2
    exit 1
}

command -v md5sum >/dev/null 2>&1 || {
    echo 'md5sum is required to generate aiorepo.index' >&2
    exit 1
}

temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT HUP INT TERM

for lua_path in ./*.lua; do
    [ -f "$lua_path" ] || continue
    file=${lua_path#./}
    write_lua_entry "$lua_path" "$temp_dir/$file.json"
done

aapt_tool=''
for apk_path in ./*.apk; do
    [ -f "$apk_path" ] || continue

    if [ -z "$aapt_tool" ]; then
        aapt_tool=$(find_aapt_tool) || {
            echo 'aapt2 (or aapt) is required when the repository contains APK files' >&2
            exit 1
        }
    fi

    file=${apk_path#./}
    write_apk_entry "$apk_path" "$temp_dir/$file.json" "$aapt_tool"
done

printf '[\n'
first_entry=true
for entry_path in "$temp_dir"/*.json; do
    if [ "$first_entry" = true ]; then
        first_entry=false
    else
        printf ',\n'
    fi
    entry=$(jq --indent 1 . "$entry_path")
    printf '%s' "$entry"
done
printf '\n]\n'
