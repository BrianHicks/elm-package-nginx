#!/usr/bin/env bash
set -euo pipefail

EIGHTEEN=$(docker run --rm --detach --name eighteen brianhicks/dummy:0.18)
NINETEEN=$(docker run --rm --detach --name nineteen brianhicks/dummy:0.19)

ROUTER=$(docker run --rm --detach --link eighteen --link nineteen --publish 8080:80 --volume "$PWD/nginx.conf":/etc/nginx/nginx.conf:ro nginx nginx-debug -g 'daemon off;')

finish() {
    if test "$FAIL" = 1; then
        echo "-- router ------------"
        docker logs "$ROUTER"
        echo "-- eighteen ----------"
        docker logs "$EIGHTEEN"
        echo "-- nineteen ----------"
        docker logs "$NINETEEN"
    fi
    docker stop "$EIGHTEEN" "$NINETEEN" "$ROUTER" > /dev/null
}
trap finish EXIT

FAIL=0

########################################

if curl -sSf -H "Host: package.elm-lang.org" localhost:8080 | grep -q 0.19; then
    echo "PASS: served 0.19 by default"
else
    echo "FAIL: did not serve 0.19 by default"
    FAIL=1
fi

########################################

if curl -sSf -H "Host: package.elm-lang.org" "localhost:8080?elm-package-version=0.18" | grep -q 0.18; then
    echo "PASS: served 0.18 with the flag"
else
    echo "FAIL: did not serve 0.18 with the flag"
    FAIL=1
fi

########################################

if curl -sSf -H "Host: package.elm-lang.org" "localhost:8080?elm-package-version=0.19" | grep -q 0.19; then
    echo "PASS: served 0.19 with the flag"
else
    echo "FAIL: did not serve 0.19 with the flag"
    FAIL=1
fi

exit "$FAIL"
