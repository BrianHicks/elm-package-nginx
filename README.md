# elm package nginx

This is an nginx configuration for package.elm-lang.org.

Rules:

1. Requests which arrive with no `User-Agent` header must be served over HTTP and use the 0.18 package server (applies to 0.17 and 0.16 as well.)
2. Requests which arrive with the `User-Agent: elm/0.19.0` header must be served over HTTPS and use the 0.19 package server.
3. Requests from browsers must be served over HTTPS, and use the latest version of the package server.

## Installing:

Replace the values in the `upstream` blocks with the locations of the actual elm-package servers.
If you want to try things out on some non-80 test port, replace `listen 80` with `listen yourport` as well.

Before running the rest of this, copy the config to your server with `scp ngingx.conf you@yourserver:~/nginx.conf`

```
# install certbot
sudo apt-get install software-properties-common
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update
sudo apt-get install nginx python-certbot-nginx

# assuming the config at `nginx.conf` is at `~/nginx.conf`
sudo mv ~/nginx.conf /etc/nginx/sites-enabled/default
sudo certbot --nginx --staging # for testing; if doing this "for real" remove --staging
```

Most of the default answers will be fine (you'll need to enter an email address, accept terms of use for the cert, and opt in or out to the EFF mailing list.)
Certbot should find `package.elm-lang.org` and ask if you want that cert (yes.)
When it asks if you want it to enable HTTPS by default, say no.
We're handling that ourselves using the rules above.

## Developing

With Docker installed, run `./test.sh`. The test harness does not set up HTTPS, but will make sure the rules above are followed.
