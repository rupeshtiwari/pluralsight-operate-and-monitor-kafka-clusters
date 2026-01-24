# Demo 3: Apply Recovery Actions Safely (Kafka Operations)

This hands-on demo walks you through a realistic operational scenario in Apache Kafka:

* Generate sustained producer traffic
* Observe consumer lag growth
* Restart a broker safely during load
* Verify ISR/URP health after restart
* Reset consumer offsets (demo recovery action)
* Confirm stability and lag returning to 0

---

## Prerequisites

* Docker Engine + Docker Compose installed
* `tmux` installed (recommended, but optional)
* Repo cloned locally
* You are in the demo directory containing:

  * `docker-compose.yml`
  * `scripts/` folder

---

## Recommended terminal layout

Use **three terminals** (or three tmux panes):

* **T1**: Broker2 logs/events
* **T2**: Control + lag view (topic, consumer, lag, restart, ISR, recovery)
* **T3**: Producer load

---

## Clean start (do this before every run)

From the demo directory:

```bash
docker compose down -v
rm -f /tmp/ops-demo-stop-load
docker compose up -d
```

Wait for containers to stabilize:

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}'
```

✅ Proceed only when brokers show **Up** and are not restarting.

---

## Step-by-step demo

### 1) Start Broker2 logs (T1)

In **T1**, run one of these and leave it running:

```bash
./scripts/06-watch-broker2-events.sh
```

If that script is not present, use:

```bash
./scripts/08-tail-broker2-logs.sh
```

✅ You should see broker2 logs/events streaming.

---

### 2) Create the topic (T2)

In **T2**:

```bash
./scripts/01-create-topic.sh
```

✅ Expected: a confirmation that the topic is created (or already exists).
If the script prints topic details, confirm you see **multiple partitions** and a **replication factor**.

---

### 3) Start the consumer (T2)

In **T2**:

```bash
./scripts/03-start-consumer.sh
```

✅ Expected: “Consumer started …” (often with a PID).
If it says “already running,” that’s fine.

---

### 4) Start the lag view (T2)

In **T2** (leave running):

```bash
./scripts/10-watch-lag.sh
```

✅ Expected:

* A lag table that refreshes in-place
* Initially lag is often **0** (or very low)
* You may briefly see “consumer group not found” while the group initializes

If “group not found” persists for >10 seconds:

* Stop lag view (Ctrl+C)
* Re-run `./scripts/03-start-consumer.sh`
* Start lag view again

---

### 5) Start producer load (T3)

In **T3**:

```bash
rm -f /tmp/ops-demo-stop-load
./scripts/02-start-load.sh
```

✅ Expected:

* Producer prints windowed send stats (throughput/latency)
* Lag in T2 begins to rise (yellow → red)

If load exits immediately with “Stop requested”:

* The stop flag file exists from a previous run
* Fix:

  ```bash
  rm -f /tmp/ops-demo-stop-load
  ./scripts/02-start-load.sh
  ```

---

### 6) Wait for lag to rise (T2)

Keep **T2** lag view visible while load runs.

✅ Expected:

* At least one partition’s lag becomes clearly non-zero
* LOG_END increases faster than CURRENT

This is the “pressure building” phase.

---

### 7) Restart broker2 safely (T2)

In **T2**:

```bash
./scripts/09-restart-broker2.sh
```

✅ Expected:

* It may print “Kafka not ready yet…” retries
* It should eventually report broker2 is reachable/ready again

In **T1**, you should see shutdown/startup lifecycle logs for broker2.

---

### 8) Verify ISR/URP after restart (T2)

In **T2**:

```bash
./scripts/12-verify-isr.sh
```

✅ Expected:

* URP should be **NO** (or return to NO shortly after restart)
* ISR should be present for partitions

If URP is YES immediately after restart:

* Wait 5–10 seconds
* Run the verify command again

---

### 9) Apply recovery action (T2)

Stop lag view if it’s still running (Ctrl+C), then run:

```bash
./scripts/13-recover-and-watch.sh
```

✅ Expected:

* Producer load is stopped
* Consumer is stopped (to prevent re-commits)
* Offsets are reset to latest
* Verification shows CURRENT close to LOG_END and lag dropping to 0
* Lag view returns showing **green zeros**

---

## Success criteria (end state)

You are “done” when:

* Broker2 restart completed and broker is reachable
* `12-verify-isr.sh` shows replication health (URP = NO)
* Lag view shows lag returning to **0** across partitions after recovery

---

## Troubleshooting

### Producer stops immediately

Cause: `/tmp/ops-demo-stop-load` exists.

Fix:

```bash
rm -f /tmp/ops-demo-stop-load
./scripts/02-start-load.sh
```

### Lag table is empty or “group not found”

Cause: consumer not running or group not created yet.

Fix:

```bash
./scripts/03-start-consumer.sh
sleep 2
./scripts/10-watch-lag.sh
```

### Lag doesn’t drop after recovery

Common causes:

* Producer is still running (LOG_END keeps rising)
* Wrong TOPIC/GROUP variables
* Consumer wasn’t fully stopped before reset

Quick checks:

```bash
docker exec broker1 kafka-consumer-groups --bootstrap-server broker1:9092 --group m3-correlation-cg --describe | head -n 40
```

Then rerun:

```bash
./scripts/13-recover-and-watch.sh
```

---

## Cleanup

```bash
docker compose down -v
rm -f /tmp/ops-demo-stop-load
```
