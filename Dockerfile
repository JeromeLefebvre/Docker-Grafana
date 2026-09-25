# Grafana + MotherDuck DuckDB datasource
# Replicates the Homebrew Grafana install on jerome-m2-7-local.
#
# IMPORTANT: GRAFANA_VERSION must be >= the version Homebrew is running
# (`brew list --versions grafana`). grafana.db cannot be downgraded.
ARG GRAFANA_VERSION=13.2.2
ARG DUCKDB_PLUGIN_VERSION=0.4.5

# ---------- stage 1: fetch the DuckDB plugin ----------
FROM alpine:3.20 AS duckdb-plugin
ARG DUCKDB_PLUGIN_VERSION
RUN apk add --no-cache curl unzip \
 && curl -fsSL -o /tmp/plugin.zip \
    "https://github.com/motherduckdb/grafana-duckdb-datasource/releases/download/v${DUCKDB_PLUGIN_VERSION}/motherduck-duckdb-datasource-${DUCKDB_PLUGIN_VERSION}.zip" \
 && unzip -q /tmp/plugin.zip -d /plugins \
 && cd /plugins/motherduck-duckdb-datasource \
 && rm -f gpx_*_darwin_* gpx_*_windows_* \
 && chmod +x gpx_*_linux_*

# ---------- stage 2: Grafana (Ubuntu image: the plugin needs glibc, Alpine/musl won't work) ----------
FROM grafana/grafana:${GRAFANA_VERSION}-ubuntu

# Keep plugins inside the image (outside /var/lib/grafana) so the data
# bind-mount can't hide them. Grafana's own auto-installed plugins land here too.
ENV GF_PATHS_PLUGINS=/opt/grafana-plugins

# Same as [plugins] allow_loading_unsigned_plugins in your grafana.ini
ENV GF_PLUGINS_ALLOW_LOADING_UNSIGNED_PLUGINS=motherduck-duckdb-datasource

ENV TZ=Australia/Perth

# The DuckDB plugin runs `SET home_directory='/tmp/duckdb'` itself and
# DuckDB stores installed extensions (httpfs, icu, ...) there. The folder
# must exist and be writable by the grafana user (uid 472), otherwise:
#   "IO Error: Can't find the home directory at '/tmp/duckdb'"
# docker-compose.yml also mounts it from the Mac so extensions persist.
USER root
RUN mkdir -p /opt/grafana-plugins /tmp/duckdb \
 && chown -R 472:0 /opt/grafana-plugins /tmp/duckdb
COPY --from=duckdb-plugin --chown=472:0 /plugins/motherduck-duckdb-datasource /opt/grafana-plugins/motherduck-duckdb-datasource
USER 472

EXPOSE 3000