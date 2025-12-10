
# 📘 **Demo 4 — Test Durability Settings Impact (acks=1 vs acks=all)**

This demo shows how Kafka durability settings affect producer throughput, latency, and delivery guarantees.
We compare:

* **acks=1** → fast but risky
* **acks=all** → slower but durable

A consumer is used to track offsets and demonstrate that lag remains stable while durability settings change.

This demo runs in a **clean three-broker cluster** and uses **four terminals**:

| Terminal | Purpose                               |
| -------- | ------------------------------------- |
| **T1**   | Cluster control + docker ops          |
| **T2**   | Broker1 shell + topic mgmt + consumer |
| **T3**   | Lag monitor                           |
| **T4**   | Producer load tests                   |

---

# ✅ **STEP 1 — Start Clean Cluster (T1)**

```bash
cd ~/pluralsight-operate-and-monitor-kafka-clusters/code/module-1/demo-4-durability-settings

docker compose down 2>/dev/null
docker compose up -d
docker ps
```

Expected:

* **broker1, broker2, broker3, zookeeper → Up**

---

# ✅ **STEP 2 — Open Broker1 Shell (T2)**

```bash
docker exec -it broker1 bash
```

---

# ✅ **STEP 3 — Delete + Recreate Topic**

Inside **T2 (Broker1 shell)**:

Delete old topic:

```bash
kafka-topics --bootstrap-server broker1:9092 --delete --topic durability-topic
```

Ignore errors.

Create fresh topic:

```bash
kafka-topics --bootstrap-server broker1:9092 \
  --create --topic durability-topic \
  --partitions 1 --replication-factor 3
```

Verify:

```bash
kafka-topics --bootstrap-server broker1:9092 \
  --describe --topic durability-topic
```

Expected:

* Leader = 1
* Replicas = 1,2,3
* ISR = 1,2,3

---

# ✅ **STEP 4 — Start Consumer Group (T2)**

```bash
kafka-console-consumer \
  --bootstrap-server broker1:9092 \
  --topic durability-topic \
  --group durability-group \
  --from-beginning
```

Leave running.

This populates the consumer group so lag monitoring works.

---

# ✅ **STEP 5 — Start Lag Monitor (T3)**

From host terminal:

```bash
./lag-monitor.sh
```

Expected:

* GROUP = durability-group
* TOPIC = durability-topic
* LAG = **0** (green)

---

# ✅ **STEP 6 — Run Producer Load With acks=1 (T4)**

```bash
docker exec -it broker1 kafka-producer-perf-test \
  --topic durability-topic \
  --num-records 300000 \
  --record-size 500 \
  --throughput -1 \
  --producer-props bootstrap.servers=broker1:9092 acks=1
```

Expected:

* **Very high throughput**
* **Low average latency**
* **50th/95th/99th percentiles lower**
* Lag remains **0**

This simulates weak durability:
Only the leader acknowledges writes → much faster, less safe.

---

# ✅ **STEP 7 — Run Producer Load With acks=all (T4)**

```bash
docker exec -it broker1 kafka-producer-perf-test \
  --topic durability-topic \
  --num-records 300000 \
  --record-size 500 \
  --throughput -1 \
  --producer-props bootstrap.servers=broker1:9092 acks=all
```

Expected:

* **Throughput drops**
* **Latency increases significantly**
* **95th/99th percentiles much higher**
* Lag still **0**

This simulates strong durability:
Writes block until **all in-sync replicas commit**.

---

# 🎯 **What Students Learn**

### ✔ Throughput vs Durability Trade-off

acks=1 = fast
acks=all = safe

### ✔ Latency Spikes Under Strong Durability

Replication round-trip slows writes.

### ✔ Replication Factor Protects From Data Loss

With RF=3 and acks=all, data survives 2 broker failures.

### ✔ Lag Is Unaffected

Durability affects **producer**, not **consumer**.

### ✔ Real-World Production Insight

Most outages tied to:

* unclean leader elections
* using acks=1 in financial/business critical flows
* brokers with slow replicas increasing commit latency

This demo mirrors what SREs see in payments, streaming analytics, fraud detection, and IoT pipelines.

---

# 🧹 **STEP 8 — Cleanup (Optional)**

Inside **T2**:

```bash
kafka-topics --bootstrap-server broker1:9092 --delete --topic durability-topic
```

Back to **T1**:

```bash
docker compose down
```

---

# 📌 **Support & 1:1 Coaching**

For deeper Kafka help, production design, or performance tuning:

### **📚 FullStackMaster | Master Kafka & Cloud**

[https://fullstackmaster.net](https://fullstackmaster.net)

### **🎯 Book a 1-on-1 Coaching Session**

[https://fullstackmaster.net/book](https://fullstackmaster.net/book)

 