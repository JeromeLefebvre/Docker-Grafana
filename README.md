# Grafana

This is my internal grafana docker image

I only need to run migrate.sh to move the initial set of commits.


/grafana-data
contains the grafana database, this file is very important as it contains all configurations from my dashboards

## Disabling plugins

See the names of current plugins
```zsh
docker exec grafana sh -c \
  'find /usr/share/grafana -name plugin.json -exec grep -h "\"id\":" {} \; | sort -u'
```

Verify the names of plugin
```
curl -s -u admin:yourpass 'http://localhost:3000/api/plugins?type=datasource' | jq -r '.[].id'
```
```
   "id": "cloudwatch",
    "id": "grafana-azure-monitor-datasource",
    "id": "grafana-postgresql-datasource",
    "id": "grafana-testdata-datasource",
    "id": "graphite",
  "id": "alertlist",
  "id": "alertmanager",
  "id": "annolist",
  "id": "barchart",
  "id": "bargauge",
  "id": "candlestick",
  "id": "canvas",
  "id": "cloudwatch",
  "id": "dashboard",
  "id": "dashlist",
  "id": "debug",
  "id": "flamegraph",
  "id": "gauge",
  "id": "geomap",
  "id": "gettingstarted",
  "id": "grafana",
  "id": "grafana-azure-monitor-datasource",
  "id": "grafana-testdata-datasource",
  "id": "graphite",
  "id": "heatmap",
  "id": "histogram",
  "id": "live",
  "id": "logs",
  "id": "logstable",
  "id": "mixed",
  "id": "news",
  "id": "nodeGraph",
  "id": "piechart",
  "id": "stat",
  "id": "state-timeline",
  "id": "status-history",
  "id": "table",
  "id": "text",
  "id": "timeseries",
  "id": "traces",
  "id": "trend",
  "id": "welcome",
  "id": "xychart",
```


Useful to conmpare what is in the ENV GF_PLUGINS_DISABLE_PLUGINS and the actual names of plugins.

curl -s -u admin:'oxpAJeKPR-6dG49*-*PfT!qm9' 'http://localhost:3000/api/plugins?type=datasource' | jq -r '.[].id'

``alertmanager
grafana-azure-monitor-datasource
cloudwatch
motherduck-duckdb-datasource
elasticsearch
stackdriver
grafana-pyroscope-datasource
graphite
influxdb
jaeger
loki
mssql
mysql
opentsdb
grafana-postgresql-datasource
prometheus
tempo
grafana-testdata-datasource
zipkin
```