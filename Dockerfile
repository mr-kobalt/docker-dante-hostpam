FROM alpine:3.7 as build

LABEL maintainer="mr.kobalt@gmail.com"

# Define parameters of the software you wish to make from source using
# enviromental variables under this section. Usage:
#   INSTALL_{SOFTWARE}_NAME - arbitrary name for the software (mandatory).
#   INSTALL_{SOFTWARE}_VERSION - version of the software (optional); useful
#       in conjunction with INSTALL_{SOFTWARE}_URL.
#   INSTALL_{SOFTWARE}_URL - direct link to *.tar.gz source archive (mandatory).
#   INSTALL_{SOFTWARE}_SHA256 - sha256 checksum of the source archive (optional).
#   INSTALL_{SOFTWARE}_CONFIG - sh command that configure software before compile.
#
# {SOFTWARE} is the name of software section and it shouldn't contain underscores.

# Check current version and checksum of Dante Proxy on official product website
# https://www.inet.no/dante/download.html
ARG INSTALL_DANTE_NAME=dante
ARG INSTALL_DANTE_VERSION=1.4.2
ARG INSTALL_DANTE_URL="https://www.inet.no/dante/files/dante-$INSTALL_DANTE_VERSION.tar.gz"
ARG INSTALL_DANTE_SHA256=4c97cff23e5c9b00ca1ec8a95ab22972813921d7fbf60fc453e3e06382fc38a7
ARG INSTALL_DANTE_CONFIG="ac_cv_func_sched_setscheduler=no ./configure \
    --prefix=/usr/local \
    --sysconfdir=/etc \
    --disable-client"
# For more information on using custom PAM-module 'pam_pwdfile.so' you should
# consult with developer repo https://github.com/tiwe-de/libpam-pwdfile
ARG INSTALL_PWDFILE_NAME=libpam-pwdfile
ARG INSTALL_PWDFILE_VERSION=1.0
ARG INSTALL_PWDFILE_URL="https://github.com/tiwe-de/libpam-pwdfile/archive/v$INSTALL_PWDFILE_VERSION.tar.gz"

RUN set -e \
    && apk update && apk upgrade --no-cache \
    && apk add --upgrade --no-cache \
        g++ \
        gcc \
        linux-pam-dev \
        make \
        tar
RUN set -e\
    && SOFTWARE=`env | grep INSTALL | while read -r line; do \
        line=${line#*_}; \
        echo ${line%%_*}; \
    done | uniq` \
    && for prog in $SOFTWARE; do \
        eval name='$INSTALL_'${prog}'_NAME'; \
        eval url='$INSTALL_'${prog}'_URL'; \
        eval sha256='$INSTALL_'${prog}'_SHA256'; \
        eval config='$INSTALL_'${prog}'_CONFIG'; \
        mkdir -p "/usr/src/${name}"; \
        wget -O "/usr/src/${name}/${name}.tar.gz" $url; \
        if [ ! -z "$sha256" ]; then \
            echo "$sha256 */usr/src/${name}/$name.tar.gz" | sha256sum -c -; \
        fi; \
        tar \
            --directory "/usr/src/${name}" \
            --extract \
            --file "/usr/src/${name}/${name}.tar.gz" \
            --strip-components 1; \
        rm -rf "/usr/src/${name}/${name}.tar.gz"; \
        cd "/usr/src/${name}"; \
        if [ ! -z "$config" ]; then \
            eval "$config"; \
        fi; \
        make && make install; \
    done
RUN if [ -z "`/usr/local/sbin/sockd -vv | grep build: | grep pam`" ]; then \
        echo "ERROR: Dante was compiled without PAM support. " \
        "Check that linux-pam-dev package is present in the system." >&2; \
        exit 1; \
    fi


FROM alpine:3.7

LABEL maintainer="mr.kobalt@gmail.com"

ENV GROUP socks
ENV USER sockd

COPY --from=build /usr/local/sbin/sockd /usr/local/sbin/
COPY --from=build /lib/security/pam_pwdfile.so /lib/security/pam_pwdfile.so
COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY ./sockd.conf.template /etc/sockd.conf
COPY ./sockd.pam /etc/pam.d/sockd

RUN set -e \
    && apk update && apk upgrade --no-cache \
    && apk add --upgrade --no-cache \
        linux-pam \
    && addgroup $GROUP \
    && adduser -D -H -s /sbin/nologin -G $GROUP $USER \
    && chown $USER:$GROUP /usr/local/bin/docker-entrypoint.sh \
    && chmod 755 /usr/local/bin/docker-entrypoint.sh \
    && chmod 644 /etc/sockd.conf /etc/pam.d/sockd

EXPOSE 1080
EXPOSE 40000-45000/udp

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["sockd", "-f", "/etc/sockd.conf", "-N", "2"]
