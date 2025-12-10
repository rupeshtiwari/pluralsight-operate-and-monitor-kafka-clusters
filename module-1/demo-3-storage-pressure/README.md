

# 📘 **Demo 3: Analyze Storage Pressure Effects**

This demo shows how **Kafka storage pressure** builds under continuous write load, how **disk usage grows past retention limits**, and how this affects **producer latency** and **consumer lag**.
It aligns with the module LO: *Analyze storage-pressure effects in Kafka clusters.*

---

## 🧩 **Concept Overview**

**Storage pressure** occurs when Kafka writes data faster than it can delete old segments.
This leads to:

* Growing disk usage
* Higher write latency
* Lag spikes
* Potential throttling or broker failure

Kafka does **not** enforce retention limits on the active segment, so disk usage can exceed the configured retention.bytes value.
Understanding this behavior is critical for operating Kafka safely in production.

---

## 🖥 **Terminal Layout**

| Terminal | Purpose                                     |
| -------- | ------------------------------------------- |
| **T1**   | Disk Usage Monitor                          |
| **T2**   | Broker1 Shell + Topic Management + Consumer |
| **T3**   | Lag Monitor                                 |
| **T4**   | Producer Load Generator                     |

All commands assume you're inside:

```bash
cd ~/pluralsight-operate-and-monitor-kafka-clusters/code/module-1/demo-3-storage-pressure
```

---

## 🚀 **STEP 1 — Start Clean Cluster (T1)**

```bash
docker compose down 2>/dev/null
docker compose up -d
docker ps
```

Expected running containers:

* broker1
* broker2
* broker3
* zookeeper

---

## 🐚 **STEP 2 — Open Broker1 Shell (T2)**

```bash
docker exec -it broker1 bash
```

---

## 📦 **STEP 3 — Create Topic With Tight Retention (T2)**

Delete if exists:

```bash
kafka-topics --bootstrap-server broker1:9092 --delete --topic storage-pressure-topic
```

Create fresh topic:

```bash
kafka-topics --bootstrap-server broker1:9092 \
  --create --topic storage-pressure-topic \
  --partitions 2 --replication-factor 3 \
  --config retention.ms=300000 \
  --config retention.bytes=1073741824
```

Verify:

```bash
kafka-topics --bootstrap-server broker1:9092 \
  --describe --topic storage-pressure-topic
```

---

## 📡 **STEP 4 — Start Consumer Group (T2)**

```bash
kafka-console-consumer \
  --bootstrap-server broker1:9092 \
  --topic storage-pressure-topic \
  --group storage-pressure-group \
  --from-beginning
```

Leave running.

---

## 📊 **STEP 5 — Start Lag Monitor (T3)**

```bash
./lag-monitor.sh
```

Expected: LAG = **0**.

---

## 💾 **STEP 6 — Start Disk Usage Monitor (T1)**

```bash
./disk-usage-monitor.sh
```

This displays the Kafka data directory size and highlights growth.

---

## 🔥 **STEP 7 — Generate Heavy Write Load (T4)**

```bash
docker exec -it broker2 kafka-producer-perf-test \
  --topic storage-pressure-topic \
  --num-records 2000000 \
  --record-size 2000 \
  --throughput -1 \
  --producer-props bootstrap.servers=broker1:9092 acks=1
```

Observe:

* **T1:** Disk usage grows rapidly (MB → GB).
* **T3:** Lag increases under disk I/O pressure.
* **T2:** Consumer tries to keep up.
* **T4:** Producer shows rising latency.

---

## 🧹 **Optional Cleanup**

```bash
docker compose down
```

---

## 🎯 **What You Learned**

* Retention.bytes does **not** cap active segment growth
* Disk pressure increases producer latency
* Lag rises due to slow disk I/O, not just slow consumers
* Kafka deletes only *old* segments, so disk doesn’t shrink immediately
* Disk usage is a critical early-warning signal for Kafka health

Monitoring these patterns helps operators avoid throttling, ISR shrink, and disk-full broker failures.

---
 For deeper help with Kafka operations or production systems, visit **[https://fullstackmaster.net](https://fullstackmaster.net)** or book a session at **[https://fullstackmaster.net/book](https://fullstackmaster.net/book)**.