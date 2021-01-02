#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Run supervisor without deamon
/usr/local/bin/supervisord -n -c /etc/supervisor/supervisord.conf