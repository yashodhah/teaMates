#!/bin/bash
set -e

if [ "${1}" = 'run_jar' ]; then
  exec java -jar order-service.jar
else
  exec "$@"
fi
