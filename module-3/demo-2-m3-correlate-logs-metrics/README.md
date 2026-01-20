````markdown
# Demo 2 (Module 3) — Correlate Logs with Metrics

This demo reuses the same observability stack (JMX Exporter → Prometheus → Grafana + Kafka Exporter) but shifts the goal from “build dashboards” to “prove causality.” You will trigger a controlled broker event, line it up with metric changes, then validate the root cause in broker logs.

## What this demo teaches
- How Kafka broker metrics flow from **JMX → Prometheus → Grafana**
- How to correlate **Throughput → Latency → Lag** (cause → early warning → symptom)
- How to validate dashboard signals using **Prometheus** as the source of truth
- Where alert rules live (Grafana) and which signals are page-worthy

---

## Prerequisites
- Docker + Docker Compose
- Ports available on your machine:
  - Grafana: `3000`
  - Prometheus: `9090`
  - Kafka brokers: `19092`, `29092`, `39092` (mapped)
  - JMX exporter ports: `5556`, `5557`, `5558`
  - Kafka exporter: `9308`

---

## Quick Start (Recommended Flow)
Run these steps exactly in order for the cleanest demo outcome.

### 1) Reset and start the environment
From the demo folder:
```bash
./stop-demo.sh && ./run-demo.sh
````

Wait **60–90 seconds** for:

* Kafka brokers to start
* JMX exporters to attach and expose metrics
* Prometheus to begin scraping
* Grafana to provision data sources + dashboards

---

## Open the UIs

### Grafana

* URL: [http://localhost:3000](http://localhost:3000)
* Login: `admin / admin`
* Dashboard: **Kafka Operational Health**

### Prometheus

* URL: [http://localhost:9090](http://localhost:9090)
* Helpful page: **Status → Targets**

  * Confirm these are **UP**:

    * `kafka-exporter`
    * `jmx-exporter-broker1`
    * `jmx-exporter-broker2`
    * `jmx-exporter-broker3`

> If Targets are DOWN, Grafana may show “No data.” Fix scraping first.

---

## Demo Actions (Terminal)

For this Module 3 demo, you will keep Grafana on screen and use the terminal only for two things:
- Trigger a clear signal change (load or broker restart)
- Prove causality by matching the Grafana timestamp to broker logs

### 0) Start log tail (leave it running)

```bash
./scripts/08-tail-broker2-logs.sh
```

### Optional: inject a clean failure for correlation

```bash
./scripts/09-restart-broker2.sh
```


Use the scripts in `scripts/` so the demo stays repeatable.

### 2) Create the topic

```bash
./scripts/01-create-topic.sh
```

Expected: topic `m3-correlation-topic` created.

### 3) Start the consumer group

```bash
./scripts/03-start-consumer.sh
```

This starts a consumer in group `m3-correlation-cg` reading from `m3-correlation-topic`.

### 4) Start producer load

```bash
./scripts/02-start-load.sh
```

This produces load at roughly **~20k records/sec** (~9–10 MB/sec). Keep it running for **45–60 seconds**.

### 5) Inject a controlled broker event (for correlation)
```bash
./scripts/09-restart-broker2.sh
```
In Grafana, note the exact time the dip starts. In the log tail, read the matching restart/leader/ISR lines.

### 6) Check lag (CLI snapshot)

```bash
./scripts/04-check-lag.sh
```

Run it a couple times during load to see lag rise/fall:

```bash
./scripts/04-check-lag.sh
sleep 5
./scripts/04-check-lag.sh
```

---

## What to observe in Grafana (Operational Story)

Open **Kafka Operational Health** dashboard and set:

* Time range: **Last 15 minutes**
* Refresh: **5s**

You should see these behaviors under load:

### Panel: Broker Throughput (Bytes In)

* Ramps up and plateaus
* Confirms traffic is reaching brokers
* Plateau + rising latency indicates pressure (not necessarily failure)

### Panel: Request Latency (Total Time p99)

* `FetchConsumer` p99 rises first (often near ~500ms during peak)
* `Produce` stays low (often <10ms), `Metadata` low (~20ms)
* p99 is an early warning signal before lag alarms

### Panel: Consumer Group Lag

* Lag increases after throughput and latency change
* Lag later drains when consumers catch up
* Lag is the symptom; throughput/latency are the earlier signals

### Panel: Under Replicated Partitions

* Should remain **0** in this demo
* Any sustained value **>0** is durability risk and is page-worthy

---

## Prometheus Validation (Source of Truth)

Prometheus confirms the raw metrics behind the Grafana panels.

Open [http://localhost:9090](http://localhost:9090) and run:

### Consumer lag (graph it)

```promql
max by (consumergroup, topic) (
  kafka_consumergroup_lag{consumergroup="m3-correlation-cg", topic="m3-correlation-topic"}
)
```

Tip: if the instant value shows `0`, switch to **Graph** and use a time range that includes the load window.

### Broker ingress rate

```promql
sum by (instance) (rate(kafka_bytes_in_total{job="kafka-jmx"}[1m]))
```

### Request latency p99

```promql
max by (request) (
  kafka_request_total_time_ms_p99{job="kafka-jmx", request=~"Produce|FetchConsumer|Metadata"}
)
```

### Under replicated partitions

```promql
sum(kafka_under_replicated_partitions{job="kafka-jmx"})
```

---

## Alerting Guidance (What to alert on)

Grafana is where alert rules live (Alerting UI or provisioned rules).

Recommended operational signals:

* **Warning**: sustained `FetchConsumer` p99 elevated (e.g., ~500ms for minutes)
* **Alert**: lag is high and **not draining** over time
* **Page**: under-replicated partitions **>0** sustained

---

## Troubleshooting

### Grafana shows “No data”

1. Prometheus → **Status → Targets** must show exporters **UP**
2. In Prometheus, confirm metrics exist:

   * `kafka_under_replicated_partitions`
   * `kafka_bytes_in_total`
   * `kafka_request_total_time_ms_p99`
3. Ensure dashboard queries match metric names (this repo uses the new names above).

### Lag is always 0

* Consumer may be keeping up.
* Keep producer load running longer (45–60s).
* Check Prometheus **Graph history** (lag may have spiked earlier then recovered).
* Verify kafka-exporter is filtering the correct names:

  * group: `m3-correlation-cg`
  * topic: `m3-correlation-topic`

---

## Stop / Cleanup

```bash
./stop-demo.sh
```

---

## Useful Reference

* Grafana: [http://localhost:3000](http://localhost:3000) (admin/admin)
* Prometheus: [http://localhost:9090](http://localhost:9090)
* Kafka exporters:

  * Kafka exporter: `:9308/metrics`
  * JMX exporters:

    * broker1: `:5556/metrics`
    * broker2: `:5557/metrics`
    * broker3: `:5558/metrics`

```
```
