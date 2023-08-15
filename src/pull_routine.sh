#!/usr/bin/env bash
# Create wrapper to execute ahriman inside the container#
CHAOTIC_ROOT=/home/nico/testing

# Create wrapper to execute ahriman inside the container
function ahriman() {
    docker compose -f "$CHAOTIC_ROOT"/docker-compose.yml exec -u ahriman -it ahriman ahriman --log-handler=console -a x86_64 "$1" "$2"
}


function parse-package-list() {
  set -euo pipefail

  if [[ ! -f "${1:-}" ]]; then
    echo 'Unrecognized routine'
    return 22
  fi

  sed -E 's/#.*//;/^\s*$/d;s/^\s+//;s/\s+$//' "$1"
}

_ROUTINE_PACKAGES="$(parse-package-list "$CHAOTIC_ROOT"/packages.txt)"

while IFS= read -r line
do
   PACKAGES+=("$line")
done <<< "$_ROUTINE_PACKAGES"

# Check if packages are installed
for i in "${PACKAGES[@]}"; do
    ahriman status "$i" | grep "Status: success" || ahriman package-add "$i"
done

