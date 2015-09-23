#!/bin/bash

# bash array join

# Match nginx worker count to cpu's
if [[ -z ${NGINX_WORKERS+x} ]]; then
  export NGINX_WORKERS="$(cat /proc/cpuinfo |grep processor | wc -l)"
fi

# If NGINX_WORKERS is not a number set a default
nre='^[0-9]+$'
if ! [[ $NGINX_WORKERS =~ $nre ]]; then
  export NGINX_WORKERS=5
fi

# Default templates
DF_TPL=(
  '/etc/nginx/nginx.conf'
  '/etc/nginx/conf.d/default.conf'
  '/usr/local/etc/php/php.ini'
  '/usr/local/etc/php-fpm.conf'
)
# User supplied templates
oIFS="$IFS"; IFS=':' read -a _TPLS <<< "$TEMPLATES"; IFS="$oIFS"
TPLS=( "${DF_TPL[@]}" "${_TPLS[@]}" ) # both

# Template configs
tpl_args=''
for i in "${TPLS[@]}"; do tpl_args+="-template $i:$i "; done
dockerize $tpl_args "$@"
