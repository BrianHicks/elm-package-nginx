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

# Elm 0.18 and prior do not have user agent headers, so they should not be
# redirected to HTTPS, and they should be served from the 0.18 server code.

if curl -sSf -A "" -H "Host: package.elm-lang.org" -D headers localhost:8080 | grep -q 0.18; then
    echo "PASS: served 0.18 for no user-agent"
else
    echo "FAIL: did not serve 0.18 for no user-agent"
fi

if ! grep -q "Location: https://package.elm-lang.org" headers; then
    echo "PASS: did not redirect to HTTPS"
else
    echo "FAIL: redirected to HTTPS"
    cat headers
    FAIL=1
fi
rm headers

########################################

# Elm 0.19 and later will have the user agent header that includes which version
# of Elm they are. They should be redirected to HTTPS, and should be served from
# the 0.19 server code.

curl -sSf -A "elm/0.19.0" -H "Host: package.elm-lang.org" -D headers 'localhost:8080/foo?bar=baz' > /dev/null
if grep -q 'Location: https://package.elm-lang.org/foo?bar=baz' headers; then
    echo "PASS: redirected 0.19 user-agent to HTTPS"
else
    echo "FAIL: did not redirect 0.19 user-agent to HTTPS"
    cat headers
    FAIL=1
fi
rm headers

#######

# Browsers and other clients which set some user-agent header should always get
# the latest version

curl -sSf -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.124 Safari/537.36" -H "Host: package.elm-lang.org" -D headers 'localhost:8080/foo?bar=baz' > /dev/null
if grep -q 'Location: https://package.elm-lang.org/foo?bar=baz' headers; then
    echo "PASS: redirected browser user-agent to HTTPS"
else
    echo "FAIL: did not redirect browser user-agent to HTTPS"
    cat headers
    FAIL=1
fi
rm headers

exit "$FAIL"
