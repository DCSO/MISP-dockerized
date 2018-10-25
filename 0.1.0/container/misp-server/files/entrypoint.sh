#!/bin/sh
set -e

# Apache gets grumpy about PID files pre-existing
rm -f /run/apache2/apache2.pid

#exec apache2 -DFOREGROUND
/usr/sbin/apache2ctl -DFOREGROUND