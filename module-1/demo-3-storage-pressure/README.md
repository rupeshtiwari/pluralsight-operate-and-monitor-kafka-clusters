 

# Demo 2: Detect Lag and ISR Changes

This demo shows how Kafka behaves when a broker becomes slow or unresponsive.
You will observe:

* **ISR drift** when a replica falls behind
* **Lag spikes** under heavy workload
* **Producer slowdown** due to reduced replication safety
* **Cluster recovery** when the broker returns

We use four terminals with live monitors to make these effects easy to see.

---

## **Terminal Layout**

Open 4 terminals and name them:

| Terminal | Role                          |
| -------- | ----------------------------- |
| **T1**   | Cluster Control & ISR Monitor |
| **T2**   | Broker1 Shell & Consumer      |
| **T3**   | Lag Monitor                   |
| **T4**   | Producer Load                 |

All host terminals (T1, T3, T4):

```bash
cd ~/pluralsight-operate-and-monitor-kafka-clusters/code/module-1/demo-2-detect-lag
```

You already have `lag-monitor.sh` and `isr-monitor.sh` in this folder.

---

## **STEP 1 — Hard Reset the Cluster (T1)**

```bash
cd ~/pluralsight-operate-and-monitor-kafka-clusters/code/module-1/demo-2-detect-lag

docker stop broker1 broker2 broker3 zookeeper 2>/dev/null
docker rm   broker1 broker2 broker3 zookeeper 2>/dev/null
docker compose down 2>/dev/null

docker compose up -d
docker ps
```

Expected:

* `broker1`, `broker2`, `broker3`, `zookeeper` → all **Up**

If broker1 is not running:

```bash
docker start broker1
```

---

## **STEP 2 — Open Broker1 Shell (T2)**

```bash
cd ~/pluralsight-operate-and-monitor-kafka-clusters/code/module-1/demo-2-detect-lag
docker exec -it broker1 bash
```

Stay inside the container.

---

## **STEP 3 — Delete & Recreate the Topic (T2)**

Inside broker1:

```bash
kafka-topics --bootstrap-server broker1:9092 --delete --topic lag-demo-topic
```

Ignore errors.

Create fresh topic:

```bash
kafka-topics --bootstrap-server broker1:9092 \
  --create --topic lag-demo-topic \
  --partitions 3 --replication-factor 3
```

Verify:

```bash
kafka-topics --bootstrap-server broker1:9092 \
  --describe --topic lag-demo-topic
```

Expected:

* **Replicas:** 3 brokers
* **ISR:** 3 brokers (green in your monitor)

---

## **STEP 4 — Start Consumer Group (T2)**

Inside broker1:

```bash
kafka-console-consumer \
  --bootstrap-server broker1:9092 \
  --topic lag-demo-topic \
  --group lag-demo-group \
  --from-beginning
```

Leave running. This creates the consumer group.

---

## **STEP 5 — Start Lag Monitor (T3)**

```bash
cd ~/pluralsight-operate-and-monitor-kafka-clusters/code/module-1/demo-2-detect-lag
./lag-monitor.sh
```

Expected:

* LAG = **0** (green)
* Table updates every 5 seconds

Leave running.

---

## **STEP 6 — Start ISR Monitor (T1)**

```bash
cd ~/pluralsight-operate-and-monitor-kafka-clusters/code/module-1/demo-2-detect-lag
./isr-monitor.sh
```

Expected:

* ISR = **three replicas** for all partitions (green)

Leave running.

---

## **STEP 7 — Generate Load on Healthy Cluster (T4)**

```bash
cd ~/pluralsight-operate-and-monitor-kafka-clusters/code/module-1/demo-2-detect-lag

docker exec -it broker1 kafka-producer-perf-test \
  --topic lag-demo-topic \
  --num-records 100000 \
  --record-size 500 \
  --throughput -1 \
  --producer-props bootstrap.servers=broker1:9092 acks=1
```

Observe:

* T2: consumer prints messages
* T3: lag moves but settles to 0
* T1: ISR remains all green

This is your **healthy baseline**.

---

## **STEP 8 — Stress Broker2 & Create Real Lag**

### **8A — Pause Broker2 (T1)**

Stop ISR monitor (Ctrl+C), then:

```bash
docker pause broker2
docker ps   # shows broker2 as (Paused)
```

Restart ISR monitor:

```bash
./isr-monitor.sh
```

Expected:

* ISR shrinks from **3 replicas → 2 replicas**
* All ISR rows are **red**

This is the degraded replication state.

---

### **8B — Heavy Workload While Degraded (T4)**

```bash
docker exec -it broker1 kafka-producer-perf-test \
  --topic lag-demo-topic \
  --num-records 2000000 \
  --record-size 500 \
  --throughput -1 \
  --producer-props bootstrap.servers=broker1:9092 acks=1
```

Observe:

* **T3:** lag spikes (yellow → red)
* **T2:** consumer falls behind
* **T1:** ISR stays red
* **T4:** producer throughput drops, latency increases

This demonstrates how **ISR drift creates lag under load**.

---

## **STEP 9 — Recovery (T1)**

```bash
docker unpause broker2
docker ps   # broker2 Up
```

Watch:

* ISR rows turn green **one partition at a time**
* Lag falls back to **0**
* System returns to full replication

Kafka automatically heals once the slow broker catches up.

---

## **STEP 10 — Stop Demo (optional)**

Inside broker1 (T2):

```bash
kafka-topics --bootstrap-server broker1:9092 --delete --topic lag-demo-topic
```

In T1:

```bash
docker compose down
```

---

# **What You Learned**

* How ISR indicates replication health
* How ISR drift occurs when brokers slow down
* How lag reacts under degraded ISR conditions
* How Kafka automatically heals and restores full ISR
* How to observe replication and consumer behavior during stress

This is the foundation for operating and monitoring Kafka clusters in production.

---
 
For deeper help with Kafka operations or production systems, visit **[https://fullstackmaster.net](https://fullstackmaster.net)** or book a session at **[https://fullstackmaster.net/book](https://fullstackmaster.net/book)**.