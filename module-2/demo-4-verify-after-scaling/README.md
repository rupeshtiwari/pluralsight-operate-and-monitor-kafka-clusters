# Demo 4 — Monitor Cluster After Scaling Actions

This demo is **verification-only**. The scaling or reassignment step is assumed complete.

You will prove three post-change signals:
1. Consumer lag stabilizes and drains
2. Leaders are evenly distributed across brokers
3. Throughput improves under load

## Prereqs
- Docker
- Kafka containers from this folder

## Start (prep before recording)

```bash
./run-demo.sh
```

What this does:
- Starts ZooKeeper + 3 brokers
- Creates/ensures the topic exists
- Starts a background consumer group so lag is meaningful

## During recording (one terminal at a time)

### 1) Start controlled load
```bash
./start-load.sh
```

### 2) Watch lag drain
```bash
./watch-lag.sh
```

### 3) Confirm leader balance (static output)
```bash
./show-leaders.sh
```

## Stop
```bash
./stop-demo.sh
```
