# About this Repo
This is GitHub repo for the Docker image of [Dante SOCKS proxy server](https://www.inet.no/dante/) with the ability of authorization  through PAM using arbitrary passwd file on the host machine thanks to [libpam-pwdfile](https://github.com/tiwe-de/libpam-pwdfile) module.

# Considerations
Be aware, that Dante PAM authentication is __not a secure way__ to authenticate users, that is the password is transmitted in clear-text unencrypted manner. While third party still cannot retrive host/guest machine system accounts usernames and passwords, thanks to `libpam-pwdfile`, it is not possible to prevent potential unauthorized usage of your proxy server.

See Dante Docs for more details: https://www.inet.no/dante/doc/1.4.x/config/auth_pam.html

# What is Dante?
Dante is a product developed by Inferno Nettverk A/S. It consists of a SOCKS server and a SOCKS client, implementing [RFC 1928](https://www.ietf.org/rfc/rfc1928.txt) and related standards. It is a flexible product that can be used to provide convenient and secure network connectivity.

# Prerequisites
Obviously, you need Docker infrastructure on your host machine installed and running. Also, in order to prepare your custom passwd file you'll need `openssl` or `mkpasswd` from the `whois` package. Check with your OS-vendor for instructions.

# How to use this image?
## Prepare passwd file
All authorized usernames and their associated passwords should be stored in custom passwd-file. It's a simple text file, containing one line for each user with two colon-separated fields; first field contains the username, second - encrypted password. You could add users with a simple command:
```shell
echo -n "username:" >> dante.pwdfile && openssl passwd -1 >> dante.pwdfile
```
You would be asked to enter password for the new user and then `dante.pwdfile` would be created. Don't forget to restrict access to this file only for user with administrative docker privileges.

## Run image
Just simply run:
```shell
docker run --name some-dante -d -p 1080:1080 -v /absolute/path/to/passwd:/etc/dante.pwdfile:ro kobalt/dante-hostpam:latest
```
> NOTE: you cannot specify relative path to passwd file directly using `-v` command-line argument, you should use absolute path instead

or equivalent using `docker-compose.yml`:
```yaml
version: "3"
services:
  proxy:
    image: kobalt/dante-hostpam:latest
    deploy:
      restart_policy:
        condition: on-failure
    volumes:
      - "./dante.pwdfile:/etc/dante.pwdfile:ro"
    ports:
      - "1080:1080"
```
## Using environment variables
You could tune your Dante configuration with some environment variables:

1. `DEBUG` - one of  the following (`0` by default)
  - `0` - no debug logging;
  - `1` - some debug logging;
  - `2` - verbose debug logging.
2. `INTERNAL_IFACE` - an IP address, an interface name or a hostname on witch server receives SOCKS requests from SOCKS clients (`0.0.0.0` by default)
3. `PORT` - port for internal connection (`1080` by default)
4. `EXTERNAL_IFACE` - an IP address, an interface name or a hostname witch server uses when forwarding data from the SOCKS clients to the external network (default gateway interface by default)

EXAMPLE using `docker run`:
```shell
docker run --name some-dante -d -e PORT=8080 -e EXTERNAL_IFACE=eth0 -e DEBUG=1 -p 8080:8080 -v /absolute/path/to/passwd:/etc/dante.pwdfile:ro kobalt/dante-hostpam:latest
```
EXAMPLE using `docker-compose.yml`:
```yaml
version: "3"
services:
  proxy:
    image: kobalt/dante-hostpam:latest
    environment:
      - PORT=8080
      - EXTERNAL_IFACE=eth0
      - DEBUG=1
    deploy:
      restart_policy:
        condition: on-failure
    volumes:
      - "./dante.pwdfile:/etc/dante.pwdfile:ro"
    ports:
      - "8080:8080"
```

## Build your own image
In order to make more significant changes into your proxy server configuration, you'll need to clone this repo and build image manually.
1. Clone repo
```shell
git clone https://github.com/mr-kobalt/docker-dante-hostpam.git
cd docker-dante-hostpam
```
2. Edit configuration files and scripts:
  - `sockd.conf.template` - main config file of Dante server. Consult with Dante Docs: https://www.inet.no/dante/doc/1.4.x/config/index.html.
  - `sockd.pam` - Linux-PAM configuration file for Dante. Refer to the _The Linux-PAM System Administrators' Guide_: http://www.linux-pam.org/Linux-PAM-html/sag-configuration.html
  > NOTE: in order to continue to use custom passwd file do not remove `pam_pwdfile.so` module from auth section

  - `docker-entrypoint.sh` - docker entrypoint shell-script; handles Dante config template.
  - `Dockerfile` - instructions for Docker about how to build an image. Current version uses multi-stage builds to compile necessary software and libraries.
  - `docker-compose.yml` - simple config for Docker Compose.
3. Build your own image
```shell
docker build -t my-own-dante-image:latest .
```

# Test your proxy server
To test that your proxy server works as intended you could run this command from your host machine
```shell
curl -x socks5h://username:password@localhost http://httpbin.org/ip
```

This request should return your proxy server IP address. In order to troubleshoot possible errors you could run Dante in debug mod by running container with `DEBUG=1` environment variable (or `DEBUG=2` for more verbose output), for example:
```shell
docker run --name dante -d DEBUG=1 -p 1080:1080 -v /absolute/path/to/passwd:/etc/dante.pwdfile:ro kobalt/dante-hostpam:latest
```

and then inspecting logs:
```shell
docker container logs dante
```
