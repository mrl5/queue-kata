#!/usr/bin/env bash
sed -i \
    "s/^#shared_preload_libraries = .*/shared_preload_libraries = 'pg_cron'/g" \
    /var/lib/postgresql/data/postgresql.conf
