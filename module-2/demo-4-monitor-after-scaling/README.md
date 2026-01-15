# 📘 Demo 4 — Monitor Cluster After Scaling Actions

This demo verifies that Kafka is **stable after scaling actions** (for example, partition reassignment).

You will prove three operator checks:

1. **Lag stabilizes and drains**
2. **Leaders are evenly distributed**
3. **ISR remains healthy under load**

This demo supports Module 2 learning objectives:

- **Observe key indicators** such as consumer lag, ISR count, throughput, and request latency
- **Evaluate cluster health** after scaling actions

---

## ✅ Prerequisites

- Docker + Docker Compose
- tmux
- watch

---

## ▶️ Run the demo

```bash
chmod +x run-demo.sh stop-demo.sh scripts/*.sh
./run-demo.sh
```

A 2x2 tmux workspace opens.

### Step order (in T4)

1. (Optional) `./scripts/01-ensure-topic-ready.sh`
   - Only run this if you did not run the reassignment demo previously
2. `./scripts/02-start-consumer.sh`
   - Leave it running so lag exists
3. `./scripts/03-watch-lag.sh`
4. `./scripts/04-watch-leader-count.sh`
5. `./scripts/06-watch-isr.sh`
6. `./scripts/05-run-load.sh`

Optional:
- `./scripts/07-run-preferred-leader-election.sh` if leaders are still skewed

---

## 🛑 Stop and clean up

```bash
./stop-demo.sh
```

