ARG BUILD_FROM
FROM $BUILD_FROM

# Add env
ENV LANG C.UTF-8

RUN mkdir -p /dnsapi

ARG ACME_VERSION
RUN apk add --no-cache curl openssl \
  && curl -s -o /acme.sh https://raw.githubusercontent.com/Neilpang/acme.sh/$ACME_VERSION/acme.sh \
  && curl -s -o /dnsapi/dns_duckdns.sh https://raw.githubusercontent.com/Neilpang/acme.sh/$ACME_VERSION/dnsapi/dns_duckdns.sh

COPY *.sh /
RUN chmod a+x /run.sh
RUN chmod a+x /acme.sh
RUN chmod a+x /dnsapi/dns_duckdns.sh

CMD [ "/run.sh" ]

