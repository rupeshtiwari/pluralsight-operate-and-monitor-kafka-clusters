````markdown
# Demo 2 (Module 3) — Correlate Logs with Metrics

This demo reuses the same observability stack (JMX Exporter → Prometheus → Grafana + Kafka Exporter) but shifts the goal from “build dashboards” to “prove causality.” You will trigger a controlled broker event, line it up with metric changes, then validate the root cause in broker logs.

## What this demo teaches
- How Kafka broker metrics flow from **JMX → Prometheus → Grafana**
- How to correlate **Throughput → Latency → Lag** (cause → early warning → symptom)
- How to validate dashboard signals using **Prometheus** as the source of truth
- Where alert rules live (Grafana) and which signals are page-worthy

**Operator LO covered in this demo**
- Restart a slow broker safely
- Reset consumer offsets for a stuck or backlogged consumer group (demo-only)
- Verify ISR/URP stability post-restart

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

## Quick Start
From the demo folder:

```bash
./stop-demo.sh && ./run-demo.sh
```

`run-demo.sh` opens a tmux layout with **three panes**:
- **T1 — Control + Lag** (you run the control scripts here)
- **T2 — Broker2 Logs (High-Signal)** (filtered log stream)
- **T3 — Producer Load** (steady load generator)

Wait **60–90 seconds** for Grafana/Prometheus to start scraping.

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

## Recording Runbook (5 minutes)

### Step A — Baseline traffic (0:00–0:20)
**T1:** `./scripts/01-create-topic.sh` (pause ~2s)

**T3:** `./scripts/02-start-load.sh` (pause ~8–10s until records/sec stabilizes)

### Step B — Consumer + lag watcher (0:20–0:55)
**T1:** `./scripts/03-start-consumer.sh` (pause ~3–5s until it says group is visible)

**T1:** `./scripts/10-watch-lag.sh` (pause ~8–10s to show values changing)

### Step C — Broker2 log stream (0:55–1:10)
**T2:** `./scripts/06-watch-broker2-events.sh` (leave it running)

### Step D — Grafana baseline (1:10–1:50)
Grafana → Dashboard **Kafka Operational Health**
- Time range: **Last 5 minutes**
- Refresh: **5s**

Just hover the timeline and call out the four quadrants: **Lag, URP, Throughput, p99 Latency**.

### Step E — Incident + recovery (1:50–3:10)
**T1:** `Ctrl+C` (stop lag watcher), then run `./scripts/09-restart-broker2.sh`

**T1:** restart lag watcher: `./scripts/10-watch-lag.sh`

Back to Grafana (20–30s): show the p99 spike and any throughput wobble around the restart time.

Glance at **T2** (10–15s): point to shutdown/start plus leader/ISR/controller events.

### Step F — Reset offsets (demo-only) (3:10–4:00)
If lag is still climbing because the consumer is intentionally slow:

**T1:** `Ctrl+C` then `./scripts/11-reset-offsets-to-latest.sh` and restart `./scripts/10-watch-lag.sh`

Expected: lag drops quickly (fast-forward recovery).

### Step G — Verify ISR/URP stability (4:00–5:00)
Grafana: confirm **URP returns to 0** and **p99 settles** after broker2 is back.

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
