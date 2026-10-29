# Grafana + MotherDuck DuckDB datasource

ARG GRAFANA_VERSION=13.3.0
ARG DUCKDB_PLUGIN_VERSION=0.4.6

# ---------- stage 1: fetch the DuckDB plugin ----------
FROM alpine:3.20 AS duckdb-plugin
# Reuse the global ARG
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

# Disable some plugins that are not needed and could be vulnerable.
ENV GF_PLUGINS_DISABLE_PLUGINS=grafana-mysql-datasource,grafana-loki-datasource,influxdb,mssql,opentsdb,zipkin,tempo,stackdriver,prometheus,jaeger,grafana-pyroscope-datasource,cloudwatch

ENV GF_SERVER_ENABLE_GZIP=false
# Keep plugins inside the image (outside /var/lib/grafana) so the data
# bind-mount can't hide them. Grafana's own auto-installed plugins land here too.
ENV GF_PATHS_PLUGINS=/opt/grafana-plugins

# This is the same as configuring the allow_loading_unsigned_plugins variable in the [plugins] section in grafana.ini 
ENV GF_PLUGINS_ALLOW_LOADING_UNSIGNED_PLUGINS=motherduck-duckdb-datasource

ENV TZ=Australia/Perth

# The DuckDB plugin runs `SET home_directory='/tmp/duckdb'` itself and
# DuckDB stores installed extensions (httpfs, icu, ...) there. The folder
# must exist and be writable by the grafana user (uid 472), otherwise:
#   "IO Error: Can't find the home directory at '/tmp/duckdb'"
# docker-compose.yml also mounts it from the Mac so extensions persist.

# 472 is the default Grafana user ID in the Grafana image, can confirm with `docker exec grafana id`
USER root
RUN mkdir -p /opt/grafana-plugins /tmp/duckdb \
 && chown -R 472:0 /opt/grafana-plugins /tmp/duckdb
# mysql is bundled with Grafana but we don't need it, so remove it to reduce the image size and attack surface.
RUN rm -rf /usr/share/grafana/data/plugins-bundled/mysql/
RUN rm -rf /usr/share/grafana/data/plugins-bundled/loki/
RUN rm -rf /usr/share/grafana/data/plugins-bundled/influxdb/
RUN rm -rf /usr/share/grafana/data/plugins-bundled/mssql/

RUN rm -rf /usr/share/grafana/data/plugins-bundled/opentsdb \
           /opt/grafana-plugins/opentsdb
RUN rm -rf /usr/share/grafana/data/plugins-bundled/zipkin \
           /opt/grafana-plugins/zipkin           
RUN rm -rf /usr/share/grafana/data/plugins-bundled/tempo \
           /opt/grafana-plugins/tempo           
RUN rm -rf /usr/share/grafana/data/plugins-bundled/stackdriver \
           /opt/grafana-plugins/stackdriver    
RUN rm -rf /usr/share/grafana/data/plugins-bundled/prometheus \
           /opt/grafana-plugins/prometheus    
RUN rm -rf /usr/share/grafana/data/plugins-bundled/jaeger \
           /opt/grafana-plugins/jaeger    
RUN rm -rf /usr/share/grafana/data/plugins-bundled/grafana-pyroscope-datasource \
           /opt/grafana-plugins/grafana-pyroscope-datasource
RUN rm -rf /usr/share/grafana/data/plugins-bundled/motherduck-duckdb-datasource/gpx_duckdb_datasource_linux_amd64 \
           /opt/grafana-plugins/motherduck-duckdb-datasource/gpx_duckdb_datasource_linux_amd64
RUN rm -rf /usr/share/grafana/data/plugins-bundled/cloudwatch \
           /opt/grafana-plugins/cloudwatch   



ENV HOME=/tmp/duckdb
COPY --from=duckdb-plugin --chown=472:0 /plugins/motherduck-duckdb-datasource /opt/grafana-plugins/motherduck-duckdb-datasource
USER 472

EXPOSE 3000