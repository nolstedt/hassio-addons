#!/bin/bash

WORK_DIR=/data/workdir
CONFIG_PATH=/data/options.json

SLEEPTIME=$(jq --raw-output '.sleep_time' $CONFIG_PATH)
DNSTXTSLEEP=$(jq --raw-output '.dns_txt_sleep' $CONFIG_PATH)

# Let's encrypt
LE_TERMS=$(jq --raw-output '.lets_encrypt.accept_terms' $CONFIG_PATH)
SYS_CERTFILE=$(jq --raw-output '.lets_encrypt.certfile' $CONFIG_PATH)
SYS_KEYFILE=$(jq --raw-output '.lets_encrypt.keyfile' $CONFIG_PATH)
LE_DOMAINS=$(jq --raw-output '.lets_encrypt.domains[]' $CONFIG_PATH)
LE_UPDATE="0"

# DuckDNS
TOKEN=$(jq --raw-output '.duck_dns.token' $CONFIG_PATH)
DUCK_DNS_DOMAINS=$(jq --raw-output '.duck_dns.domains[]' $CONFIG_PATH)
export DuckDNS_Token="$TOKEN"

#acme
#RENEW_SECONDS=10
RENEW_SECONDS=43200

function copy_certs() {
  echo "copy certs to /ssl/"
  cp -f "$WORK_DIR/fullchain.pem" "/ssl/$SYS_CERTFILE"
  cp -f "$WORK_DIR/privkey.pem" "/ssl/$SYS_KEYFILE"
}

function renew_certs() {
  echo "renew certs"
  if [ "$LE_TERMS" == "true" ]; then
    if [ "$LE_UPDATE" == 0 ]; then
      echo "first issue"

      local domain_args=()
      for domain in $LE_DOMAINS; do
        domain_args+=("-d" "$domain")
      done

      #./acme.sh --force --staging \
      ./acme.sh \
        --dnssleep $DNSTXTSLEEP \
        --issue "${domain_args[@]}" --dns dns_duckdns \
        --cert-home $WORK_DIR \
        --cert-file $WORK_DIR/cert --key-file "$WORK_DIR/privkey.pem" \
        --ca-file $WORK_DIR/ca --fullchain-file "$WORK_DIR/fullchain.pem"

    else
      #./acme.sh $ACME_FORCE $ACME_STAGING \
      ./acme.sh \
        --dnssleep $DNSTXTSLEEP \
        --renew "${domain_args[@]}" \
        --cert-home $WORK_DIR \
        --cert-file $WORK_DIR/cert --key-file "$WORK_DIR/privkey.pem" \
        --ca-file $WORK_DIR/ca --fullchain-file "$WORK_DIR/fullchain.pem"
    fi

    if [ $? -eq 0 ]; then
      LE_UPDATE="$(date +%s)"
      copy_certs
    fi

  fi
}

while true; do
  echo "update duck dns"
  answer="$(curl -sk "https://www.duckdns.org/update?domains=$DUCK_DNS_DOMAINS&token=$TOKEN&ip=&verbose=true")" || true
  echo "$(date): $answer"

  now="$(date +%s)"
  if [ "$LE_TERMS" == "true" ] && [ $((now - LE_UPDATE)) -ge "$RENEW_SECONDS" ]; then
    renew_certs
  fi

  echo "sleep for: $SLEEPTIME"
  sleep "$SLEEPTIME"
done

