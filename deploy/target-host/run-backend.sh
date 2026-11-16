#!/usr/bin/env bash
set -euo pipefail

release_root="${DZDP_RELEASE_ROOT:-/opt/dazhongdianping}"
current_link="$release_root/current"
release_dir="$release_root/releases"

if [[ ! -L "$current_link" ]]; then
  echo "Current release symlink is missing: $current_link" >&2
  exit 1
fi

current_dir="$(readlink -f "$current_link")"
case "$current_dir" in
  "$release_dir"/*) ;;
  *)
    echo "Current release points outside the managed release directory" >&2
    exit 1
    ;;
esac

if [[ ! -d "$current_dir/backend" ]]; then
  echo "Backend directory is missing from the current release" >&2
  exit 1
fi

mapfile -d '' jars < <(find "$current_dir/backend" -maxdepth 1 -type f -name '*.jar' -print0)
if [[ "${#jars[@]}" -ne 1 ]]; then
  echo "The current release must contain exactly one backend JAR" >&2
  exit 1
fi

exec /usr/bin/java -jar "${jars[0]}"
