
# 📘 **Demo 5: Tune Producer Throughput Settings**

This demo teaches how to **increase Kafka producer throughput safely** by tuning the two most influential batching settings:

* **batch.size**
* **linger.ms**

You will learn how these settings affect **throughput**, **latency**, and **consumer lag** — and how to validate the tuning using live ISR and lag monitors.

This aligns directly with the Learning Objective:

> **Adjust producer configurations to balance throughput and latency while maintaining cluster stability.**

---

## 🧩 **Concept Overview**

A Kafka producer doesn’t send messages one at a time.
It batches messages together before sending them.
Two settings control that batching behavior:

### **1. batch.size**

Sets the maximum size of a batch (in bytes).
Larger batches → higher throughput → slightly more latency.

### **2. linger.ms**

Adds a small wait time to allow batches to fill.
Small linger values → very high throughput → increased latency.

Senior operators always tune producers with **three safety indicators**:

1. **ISR Health** → Replication stability
2. **Lag Behavior** → Latency impact
3. **Measured Throughput** → Actual performance gain

This demo shows how to read all three correctly.

---

## 🖥 **Terminal Layout**

You will use a **four-terminal layout**:

| Terminal | Purpose                             |
| -------- | ----------------------------------- |
| **T1**   | Cluster Control + ISR Monitor       |
| **T2**   | Consumer (broker1)                  |
| **T3**   | Lag Monitor                         |
| **T4**   | Producer Load Generator (perf test) |

All commands assume you're inside:

```bash
cd ~/pluralsight-operate-and-monitor-kafka-clusters/code/module-1/demo-5-producer-tuning
```

---

## 🛠 **Scripts Provided**

This demo requires two watch scripts.

### **1. ISR Monitor**

`isr-monitor-tuning.sh`
Shows replica health and highlights ISR shrink.

### **2. Lag Monitor**

`lag-monitor-tuning.sh`
Shows lag changes with color-coded indicators.

Make both executable:

```bash
chmod +x isr-monitor-tuning.sh
chmod +x lag-monitor-tuning.sh
```

---

# 🚀 **STEP 1 — Start Clean Cluster (T1)**

```bash
docker compose down 2>/dev/null
docker compose up -d
docker ps
```

Expected containers:

* broker1
* broker2
* broker3
* zookeeper

All must be **Up**.
No paused or restarting containers allowed.

---

# 📦 **STEP 2 — Create Topic (T1)**

Delete and recreate the topic to ensure a clean partition state:

```bash
docker exec broker1 kafka-topics \
  --bootstrap-server broker1:9092 \
  --delete --topic throughput-demo-topic 2>/dev/null

docker exec broker1 kafka-topics \
  --bootstrap-server broker1:9092 \
  --create --topic throughput-demo-topic \
  --partitions 3 --replication-factor 3

docker exec broker1 kafka-topics \
  --bootstrap-server broker1:9092 \
  --describe --topic throughput-demo-topic
```

---

# 👀 **STEP 3 — Start ISR Monitor (T1)**

```bash
./isr-monitor-tuning.sh
```

Expected:

* **ISR = 3,3,3** across all partitions
* No red values
* No replica falling behind

This is your replication safety baseline.

---

# 📡 **STEP 4 — Start Consumer (T2)**

```bash
docker exec -it broker1 kafka-console-consumer \
  --bootstrap-server broker1:9092 \
  --topic throughput-demo-topic \
  --group tuning-demo-group
```

This gives you real-time message flow.

---

# 📊 **STEP 5 — Start Lag Monitor (T3)**

```bash
./lag-monitor-tuning.sh
```

Expected:

* Lag = **0** (green)
* All partitions defined
* No warnings or errors

Lag rising during tuning is normal.
Lag remaining high is **not**.

---

# ⚙️ **STEP 6 — Baseline Throughput Test (T4)**

```bash
docker exec -it broker2 kafka-producer-perf-test \
  --topic throughput-demo-topic \
  --num-records 200000 \
  --record-size 200 \
  --throughput -1 \
  --producer-props bootstrap.servers=broker1:9092 acks=1
```

Observe:

* **T1** – ISR remains green
* **T3** – Lag remains zero
* **T2** – Steady flow of messages
* **T4** – Baseline throughput and latency values

This is your foundation for comparison.

---

# 🚀 **STEP 7 — Tuning 1: Increase batch.size (T4)**

```bash
docker exec -it broker2 kafka-producer-perf-test \
  --topic throughput-demo-topic \
  --num-records 200000 \
  --record-size 200 \
  --throughput -1 \
  --producer-props bootstrap.servers=broker1:9092 acks=1 batch.size=65536
```

Watch for:

* Higher records/sec
* Higher MB/sec
* Short yellow lag spikes
* ISR must remain green

Operator insight:
**batch.size gives you the biggest boost for free.**
It increases throughput without changing message semantics.

---

# 🚀 **STEP 8 — Tuning 2: Add linger.ms (T4)**

```bash
docker exec -it broker2 kafka-producer-perf-test \
  --topic throughput-demo-topic \
  --num-records 200000 \
  --record-size 200 \
  --throughput -1 \
  --producer-props bootstrap.servers=broker1:9092 acks=1 batch.size=65536 linger.ms=10
```

Watch for:

* Even higher throughput
* Bursty consumer behavior
* Lag spikes but returning to zero
* ISR remains green

Operator insight:
**linger.ms is powerful but dangerous**.
Even small values raise latency.
Use only when throughput truly matters.

---

# 🎯 **What You Learned**

* **batch.size** increases throughput by sending larger payloads
* **linger.ms** increases throughput further by waiting for batches to fill
* Lag spikes are expected but must recover
* ISR stability is non-negotiable
* Correct tuning requires real-time validation via ISR + lag + throughput

The key principle:

> **Throughput tuning is successful only when performance improves and durability remains untouched.**

---

# 🧹 **Cleanup (Optional)**

```bash
docker compose down
```

If you plan to run the next demo immediately, you can skip cleanup.

---

# 🤝 **Need 1:1 Kafka Coaching?**

If you want to master real-world Kafka operations, tuning, troubleshooting, and architecture:

**Book a 1:1 coaching session with me:**
👉 [https://fullstackmaster.net/book](https://fullstackmaster.net/book)

Or explore more at:
👉 [https://fullstackmaster.net](https://fullstackmaster.net)

---

 