# Demo 4 — Monitor Cluster After Scaling Actions

This demo is **verification-only**.
The scaling or partition reassignment step is **assumed complete**.

The goal is to validate that a Kafka cluster is truly healthy **after** a scaling action, using real operational signals instead of assumptions.

---

## What This Demo Proves

By the end of this demo, you will verify three post-scale signals that matter in production:

1. **Consumer lag stabilizes and drains** under load
2. **Leaders are evenly distributed** across brokers
3. **Throughput holds steady** while traffic is applied

If any of these fail, the scaling action did not achieve its goal.

---

## Prerequisites

* Docker (Docker Desktop or equivalent)
* Kafka containers provided in this folder
* No external Kafka installation required

---

## Demo Flow (High Level)

This demo follows a deliberate operator workflow:

1. Prepare a deterministic environment
2. Establish a clean baseline
3. Apply controlled load
4. Observe lag behavior live
5. Verify leader balance after load

Each step mirrors how experienced operators validate changes in production.

---

## Step 1 — Prepare the Environment (Before Recording)

Run the setup script:

```bash
./run-demo.sh
```

This script prepares a known-good starting point. It:

* Starts ZooKeeper and three Kafka brokers
* Verifies all brokers are healthy
* Creates or validates the topic
* Starts a background consumer group
* Seeds offsets so consumer lag is visible immediately

You should see confirmation messages ending with **offsets visible**.
If lag is not visible, do not proceed with the demo.

---

## Step 2 — Start the Demo Recording

Use **one terminal at a time**, switching deliberately.

### Terminal B — Observation (Lag)

Start the lag view first to establish a baseline:

```bash
./watch-lag.sh
```

At rest, lag should be **zero across all partitions**.
This confirms the system is caught up before load is applied.

---

### Terminal A — Action (Load)

Apply controlled producer load:

```bash
./start-load.sh
```

This generates a fixed volume of traffic at a steady rate.
Watch throughput and latency to confirm producers are healthy.

---

### Terminal B — Observation (Lag Under Load)

While load is active, return to the lag view:

```bash
./watch-lag.sh
```

Expected behavior:

* Lag may rise briefly
* Lag should **stabilize**
* Lag should **drain back to zero** after load completes

Unbounded or persistent lag indicates a real problem.

---

### Terminal A — Verification (Leader Distribution)

After load completes, verify leader balance:

```bash
./show-leaders.sh
```

Expected outcome:

* Leaders evenly spread across brokers
* No single broker overloaded with leadership

Leader imbalance after scaling is a common root cause of future lag spikes.

---

## Step 3 — Stop the Demo

When finished:

```bash
./stop-demo.sh
```

This shuts down containers cleanly.

---

## How to Interpret Results

* **Lag drains to zero** → Consumers can keep up
* **Throughput stays steady** → Brokers handle load
* **Leaders balanced** → Writes are evenly distributed

If all three hold, the scaling action was successful.

---

## Want to Go Deeper?

If you want help:

* diagnosing lag that *doesn’t* drain
* fixing leader imbalance
* designing safer scaling or rebalance strategies
* or reviewing your real Kafka setup

You can book a **1:1 technical session** with me here:

👉 **[https://fullstackmaster.net/book](https://fullstackmaster.net/book)**

These sessions focus on real production problems, not toy examples.

---
