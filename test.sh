#!/usr/bin/env bash
set -euo pipefail

EIGHTEEN=$(docker run --rm --detach --name eighteen brianhicks/dummy:0.18)
NINETEEN=$(docker run --rm --detach --name nineteen brianhicks/dummy:0.19)

ROUTER=$(docker run --rm --detach --link eighteen --link nineteen --publish 8080:80 --volume "$PWD/nginx.conf":/etc/nginx/conf.d/default.conf:ro nginx nginx-debug -g 'daemon off;')

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

curl -sSf -H "Host: package.elm-lang.org" -D headers localhost:8080 > /dev/null
if grep -q "Location: https://package.elm-lang.org" headers; then
    echo "PASS: redirected to HTTPS"
else
    echo "FAIL: did not redirect to HTTPS"
    cat headers
    FAIL=1
fi
rm headers

########################################

if curl -sSf -H "Host: package.elm-lang.org" "localhost:8080?elm-package-version=0.18" | grep -q 0.18; then
    echo "PASS: served 0.18 with the flag"
else
    echo "FAIL: did not serve 0.18 with the flag"
    FAIL=1
fi

########################################

curl -sSf -H "Host: package.elm-lang.org" -D headers 'localhost:8080?elm-package-version=0.19' > /dev/null
if grep -q 'Location: https://package.elm-lang.org/?elm-package-version=0.19' headers; then
    echo "PASS: redirected 0.19 flag to HTTPS"
else
    echo "FAIL: did not redirect 0.19 flag to HTTPS"
    cat headers
    FAIL=1
fi
rm headers

########################################

curl -sSf -H "Host: package.elm-lang.org" -D headers 'localhost:8080/foo/bar/baz?elm-package-version=0.19' > /dev/null
if grep -q 'Location: https://package.elm-lang.org/foo/bar/baz?elm-package-version=0.19' headers; then
    echo "PASS: redirection includes all path components"
else
    echo "FAIL: redirection did not include all path components"
    cat headers
    FAIL=1
fi
rm headers

exit "$FAIL"
