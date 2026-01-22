# Demo-2 | Module 3🧪 Kafka Demo: Lag, Broker Restart, and Observability

> 🎯 **Goal**: Demonstrate how Kafka handles broker failure, how lag builds up under pressure, and how logs/metrics help us debug.
> 🧠 You’ll learn: Lag mechanics, ISR changes, controller elections, log-metric correlation, and real-world recovery patterns.

---

## 🔧 Prerequisites

Make sure the following are installed:

* Docker & Docker Compose
* `bash`, `tmux`, and basic Linux tools
* No prior Zookeeper/Kafka setup required — demo is self-contained

---

## 📁 Folder Structure

| File / Script                              | Purpose                                  |
| ------------------------------------------ | ---------------------------------------- |
| `run-demo.sh`                              | Starts or stops the full environment     |
| `scripts/01-create-topic.sh`               | Creates a test topic                     |
| `scripts/02-start-load.sh`                 | Starts producer load                     |
| `scripts/03-start-consumer.sh`             | Starts the (intentionally) slow consumer |
| `scripts/06-watch-broker2-events.sh`       | Live logs of broker2, filtered           |
| `scripts/10-watch-lag.sh`                  | Shows consumer group lag live            |
| `scripts/09-restart-broker2.sh`            | Simulates broker2 failure                |
| `scripts/14-reset-and-restart-consumer.sh` | Recovery script after incident           |

---

## ✅ STEP-BY-STEP: Full Demo Flow (~5 minutes)

> ⏱️ Time-sensitive demo — no idle screen >10s
> 🎥 You’ll use 3 terminal panes via `tmux`:
>
> * T1 = Broker logs
> * T2 = Control + Lag watcher
> * T3 = Producer load

---

### 🔄 Step 0: Reset Everything (Clean Start)

```bash
./run-demo.sh --down
./run-demo.sh
```

⏱️ Wait 10–15 seconds → tmux auto-opens
🖼️ Ensure all 3 panes are visible

---

### 🧩 T1 (TOP) — Broker Logs

```bash
./scripts/06-watch-broker2-events.sh
```

🧠 This shows key events from broker2: controller activity, ISR changes, resignations, etc.
✅ Let it run throughout.

---

### 🚀 T3 (RIGHT) — Start Producer Load

```bash
./scripts/02-start-load.sh
```

📈 Expect live output like:

```
49995 records sent, avg latency: 6.2ms, 99th percentile: 10.4ms
```

✅ This runs for ~5 minutes in short windows
💡 **Tip**: Throughput stays stable even during broker failure

---

### 🛠️ T2 (BOTTOM LEFT) — Setup + Lag Watcher

1. **Create Topic**

   ```bash
   ./scripts/01-create-topic.sh
   ```

2. **Start Slow Consumer**

   ```bash
   ./scripts/03-start-consumer.sh
   ```

   ⏱️ Lag will be near 0 — for now.

3. **Start Lag Watcher**

   ```bash
   ./scripts/10-watch-lag.sh
   ```

   🧠 Watch `LAG` column for each partition
   ✅ This will spike later when broker fails

---

### 📊 GRAFANA — Open Dashboard

1. Go to: [http://localhost:3000](http://localhost:3000)
2. Login: `admin` / `admin`
3. Set:

   * **Time Range**: Last 5 minutes
   * **Auto Refresh**: 5s

🎯 Baseline:

* p99 latency should be low
* Consumer lag near 0
* Throughput steady

---

### 💥 Step 5: Simulate Failure

```bash
./scripts/09-restart-broker2.sh
```

📉 This simulates a broker crash
✅ Watch for log events like `Resigned`, `LeaderAndIsr`, `ControllerMovedException`

---

### 🔍 Observe Lag & Logs

* **T1 logs**: Will show resigns, elections, ISR shrink
* **T2 lag**: Will explode — thousands to millions
* **Grafana**:

  * p99 latency will jump
  * Consumer lag line spikes
  * (URP may temporarily increase)

---

### 🔁 Step 6: Recovery

```bash
./scripts/14-reset-and-restart-consumer.sh
```

✅ This kills old consumer, clears port conflicts, starts fresh one
🎯 Intended to demonstrate Kafka’s ability to recover

---

### 🧠 Final Observations

* **Producer stays strong**: Even under chaos, producer never stopped — kept ~49.9K msg/5s
* **Lag may stay elevated**: In real systems, recovery may take time, and that’s realistic
* **Metrics > Logs Alone**: Only by combining log events + metrics did we see the big picture

---

## 📌 What You Learned

✅ Lag spikes during instability
✅ Broker restarts → ISR shrink → Controller re-election
✅ p99 latency is a **tail signal**
✅ Kafka buffers producers — consumer slowdown = lag
✅ Resetting consumer helps simulate real-world recovery
✅ This is not just a demo — it’s incident muscle-memory training

---

## 📎 Tips

* Use `watch-lag.sh` like a radar: fast refresh, low clutter
* Scan for **controller epoch changes** in logs — sign of broker elections
* p99 is the alert trigger — track it before ops tickets track you
