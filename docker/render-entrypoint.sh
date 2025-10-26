#!/bin/bash
set -e

# Default PORT if not provided by the environment
: "${PORT:=80}"

# Replace Listen 80 by Listen $PORT in Apache config
if grep -q "Listen 80" /etc/apache2/ports.conf 2>/dev/null; then
  sed -i "s/Listen 80/Listen ${PORT}/g" /etc/apache2/ports.conf || true
fi

# Replace :80 in virtual host if present
if [ -f /etc/apache2/sites-available/000-default.conf ]; then
  sed -i "s/:80/:${PORT}/g" /etc/apache2/sites-available/000-default.conf || true
fi

echo "Starting Apache on port ${PORT}"
exec apache2-foreground