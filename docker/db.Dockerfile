FROM postgres:15.3 as build-env

RUN apt-get update \
    && apt-get install postgresql-15-cron \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY pg_cron_init.sh /docker-entrypoint-initdb.d
