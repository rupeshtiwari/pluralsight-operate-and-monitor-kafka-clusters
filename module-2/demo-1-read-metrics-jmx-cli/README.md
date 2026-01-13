

# 📘 Demo 1 — Read Kafka Metrics via JMX and CLI (Module 2)

This demo teaches how Kafka operators observe **broker health**, **load**, and **consumer behavior** in real time using **JMX metrics** and **Kafka CLI tools** — without dashboards.

You will run a live Kafka cluster, generate producer traffic, start a consumer group, and **correlate**:

**Producer load → Broker JMX metrics → Consumer group lag**

---

## 🎯 Learning Objectives (LO)

By the end of this demo, you can:

* View **JMX endpoints / broker stats** for health and pressure signals
* Check **consumer lag** using `kafka-consumer-groups`
* Inspect **throughput** and **request latency** using JMX-derived metrics

---

## 🧠 Operator mindset (why this matters)

In real incidents, dashboards are often missing, lagging, or misleading.
JMX + CLI is your fastest “ground truth” path to answer:

* Are brokers healthy or saturated?
* Is lag a consumer issue or broker issue?
* Is throughput actually flowing?
* Is latency rising before failure?

---

## ✅ Prerequisites

* Docker Desktop (or Docker Engine on Linux)
* Docker Compose v2
* tmux (recommended if you want the same multi-pane layout as the course)
* Git (recommended)

Verify:

```bash
docker info
docker compose version
tmux -V
```

> You do NOT need to install Kafka, Java, or JMX tools locally. Everything runs in containers.

---

## 📂 Working Directory

```bash
cd ~/pluralsight-operate-and-monitor-kafka-clusters/code/module-2/demo-1-read-metrics-jmx-cli
```

---

## 🖥️ Terminal Layout (recommended)

This demo is easiest to follow with three panes:

| Pane | Purpose              |
| ---- | -------------------- |
| T1   | Broker Metrics (JMX) |
| T2   | Consumer Lag (CLI)   |
| T3   | Producer Load        |

Start the environment:

```bash
./run-demo.sh
```

This will:

* clean old containers (if any)
* start the Kafka cluster
* open your demo layout (if the script is configured to do so)

> Nothing auto-runs inside panes. You drive the steps below.

---

# 🧭 Demo Flow (follow in this order)

## STEP 1 — Create the topic (T1)

```bash
./scripts/01-create-topic.sh
```

Expected:

* Topic created (typically 3 partitions, RF=3)

---

## STEP 2 — Start producer load (T3)

```bash
./scripts/02-start-load.sh
```

Leave it running.
This produces continuous traffic so lag + JMX metrics are meaningful.

What to watch:

* records/sec
* avg/max latency

---

## STEP 3 — Check lag BEFORE consumer starts (T2)

```bash
./scripts/04-check-lag.sh
```

Expected:

* `Consumer group not found yet`

✅ This is correct. It confirms there is no active group yet.

---

## STEP 4 — Start the consumer group (T2)

```bash
./scripts/03-start-consumer.sh &
```

Runs in background so you can keep running lag checks.

---

## STEP 5 — Observe lag (run twice) (T2)

```bash
./scripts/04-check-lag.sh
sleep 2
./scripts/04-check-lag.sh
```

What to watch:

* lag appears per partition
* it may rise if producer outpaces consumer
* the key is interpreting it alongside broker metrics

---

## STEP 6 — Read broker metrics via JMX (T1)

Run these one by one:

```bash
./scripts/05-jmx-broker-stats.sh
./scripts/06-jmx-throughput.sh
./scripts/07-jmx-request-latency.sh
```

What these tell you:

* **Controller sanity** (e.g., ActiveControllerCount)
* **Broker pressure** (e.g., RequestQueueSize or similar pressure signal)
* **Throughput** (BytesInPerSec / traffic rate)
* **Request latency** (produce/fetch latency trends)

---

## ✅ How to interpret results (quick cheat sheet)

### If lag rises but:

* RequestQueueSize is low
* latency remains stable
* throughput is steady

→ brokers are healthy; consumer is simply slower than producer.

### If lag rises AND:

* request queue grows
* request latency climbs
* throughput becomes unstable

→ brokers are under stress; investigate broker saturation / IO / network / partition hotspots.

---

# 🛑 Stop / Destroy the demo environment (clean teardown)

## Option A (recommended)

```bash
./run-demo.sh --down
```

## Option B (manual)

```bash
docker compose down -v --remove-orphans
```

If you still see conflicts:

```bash
docker rm -f broker1 broker2 broker3 zookeeper 2>/dev/null || true
docker network prune -f
```

---

## 📌 Support & 1:1 Coaching

FullStackMaster — Master Kafka & Cloud
[https://fullstackmaster.net](https://fullstackmaster.net)

Book a 1-on-1 Session
[https://fullstackmaster.net/book](https://fullstackmaster.net/book)

---

**Author:** Rupesh Tiwari
Senior Customer Solutions Manager, AWS
Pluralsight Course: Operate and Monitor Kafka Clusters

---
 