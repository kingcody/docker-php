#!/bin/bash

# Tweak nginx to match the workers to cpu's
procs="$(cat /proc/cpuinfo |grep processor | wc -l)"
sed -e "s/worker_processes 5/worker_processes $procs/" -i /etc/nginx/nginx.conf

# Start supervisord and services
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
