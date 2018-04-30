#!/usr/bin/env bash
set -euo pipefail

EIGHTEEN=$(docker run --rm --detach --name eighteen brianhicks/dummy:0.18)
NINETEEN=$(docker run --rm --detach --name nineteen brianhicks/dummy:0.18)

ROUTER=$(docker run --rm --detach --link eighteen --link nineteen --publish 8080:80 --volume "$PWD/nginx.conf":/etc/nginx/nginx.conf:ro nginx nginx-debug -g 'daemon off;')

finish() {
    docker logs "$ROUTER"
    docker stop "$EIGHTEEN" "$NINETEEN" "$ROUTER"
}
trap finish EXIT

curl localhost:8080
