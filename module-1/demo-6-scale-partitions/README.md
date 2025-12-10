# 📘 **Demo 6 — Monitor Cluster After Scaling Actions**

This demo shows how to verify Kafka cluster health **after scaling partitions**.
You will validate ISR stability, leader rebalancing, consumer lag behavior, and producer throughput improvements.

This aligns with the learning objectives:

* Verify **lag stabilization** after a rebalance
* Confirm **leaders are evenly distributed**
* Observe **throughput improvements** across brokers

All steps below run in a **clean two-broker cluster** using **five terminals**.

---

## 🖥 **Terminal Layout**

| Terminal | Purpose                               |
| -------- | ------------------------------------- |
| **T1**   | ISR Monitor                           |
| **T2**   | Broker1 shell + topic mgmt + consumer |
| **T3**   | Lag Monitor                           |
| **T4**   | Producer Load                         |
| **T5**   | Leader Monitor                        |

All commands assume you're inside:

```bash
cd ~/pluralsight-operate-and-monitor-kafka-clusters/code/module-1/demo-6-scale-partitions
```

Launch the tmux layout:

```bash
./start-demo-6-layout.sh
```

---

# 🚀 **STEP 1 — Start Clean Cluster (host)**

```bash
docker compose down 2>/dev/null
docker compose up -d
docker ps
```

Expected containers:

* `broker1`
* `broker3`
* `zookeeper`

---

# 🐚 **STEP 2 — Open Broker1 Shell (T2)**

```bash
docker exec -it broker1 bash
```

---

# 📦 **STEP 3 — Create Topic `scale-demo-topic-v2` (T2 inside broker1)**

```bash
kafka-topics --bootstrap-server broker1:9092 \
  --create --topic scale-demo-topic-v2 \
  --partitions 6 --replication-factor 2
```

Verify:

```bash
kafka-topics --bootstrap-server broker1:9092 \
  --describe --topic scale-demo-topic-v2
```

Expected:

* **Leader is 1 or 3**, not `none`
* **Replicas** = two brokers
* **ISR** = both replicas in sync

---

# 🧑‍🏫 **STEP 4 — Start Consumer Group (T2 inside broker1)**

```bash
kafka-console-consumer \
  --bootstrap-server broker1:9092 \
  --topic scale-demo-topic-v2 \
  --group scale-demo-group
```

Leave it running.

---

# ⚡ **STEP 5 — Warm Up Offsets (T4)**

This ensures lag monitor sees the group.

```bash
docker exec -it broker3 kafka-producer-perf-test \
  --topic scale-demo-topic-v2 \
  --num-records 20000 \
  --record-size 200 \
  --throughput -1 \
  --producer-props bootstrap.servers=broker1:9092 acks=1
```

---

# 📊 **STEP 6 — Start Monitoring Tools**

### **T1 — ISR Monitor**

```bash
./isr-monitor-scale.sh
```

You should see all ISR entries **green**.

---

### **T5 — Leader Distribution Monitor**

```bash
./leader-monitor-scale.sh
```

Expected:

```
broker1: 3 leaders
broker3: 3 leaders
```

Both shown in **green** (balanced).

---

### **T3 — Lag Monitor**

```bash
./lag-monitor-scale.sh
```

You should now see:

* Rows for all partitions
* `LAG = 0` in **green**

---

# 🔥 **STEP 7 — Main Throughput Load (T4)**

```bash
docker exec -it broker3 kafka-producer-perf-test \
  --topic scale-demo-topic-v2 \
  --num-records 500000 \
  --record-size 200 \
  --throughput -1 \
  --producer-props bootstrap.servers=broker1:9092 acks=1
```

### Watch what happens:

| Terminal | What You Narrate                                                    |
| -------- | ------------------------------------------------------------------- |
| **T4**   | Throughput increases after scaling. Records/sec and MB/sec improve. |
| **T5**   | Leaders remain balanced. No hotspot.                                |
| **T1**   | ISR remains stable and green. Replication healthy.                  |
| **T3**   | Lag briefly spikes, then returns to **0** → system has stabilized.  |
| **T2**   | Consumer keeps up with the scaled partitions.                       |

This validates the cluster is **healthy and optimized** after scaling.

---

# 🛑 **STEP 8 — Stop Demo (Keep Cluster)**

Do **not** shut down the cluster.
Simply stop each pane:

* `Ctrl+C` in T4 (producer)
* `Ctrl+C` in T3 (lag monitor)
* `Ctrl+C` in T5 (leader monitor)
* `Ctrl+C` in T1 (isr monitor)
* `Ctrl+C` in T2 (consumer)

Cluster stays up for subsequent demos.

---

# 🎯 **What You Learned**

* **Lag stabilizes** after scaling partitions
* **Leaders rebalance evenly** across brokers
* **ISR remains healthy** under load
* **Producer throughput improves** due to better parallelism
* **Scaling verification is a must** before promoting changes to production

This is the exact workflow senior Kafka SREs use in real clusters.

---

# 📌 **Support & 1:1 Coaching**

For deeper Kafka help or production architecture reviews:

### **📚 FullStackMaster | Master Kafka & Cloud**

[https://fullstackmaster.net](https://fullstackmaster.net)

### **🎯 Book a 1-on-1 Coaching Session**

[https://fullstackmaster.net/book](https://fullstackmaster.net/book)
 