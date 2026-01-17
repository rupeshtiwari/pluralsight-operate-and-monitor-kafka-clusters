# Demo 1 (Module 3) - Diagnose Lag and Consumer Issues

This demo is **diagnosis-only**. You will confirm lag, verify consumer health, and correlate lag with broker load.

**Do not fix anything in this demo.** No restarts, no offset resets, no scaling.

## Start

```bash
./run-demo.sh
```

- Starts ZooKeeper and 3 Kafka brokers
- Ensures the demo topic exists
- Opens an asymmetric `tmux` layout (if `tmux` is installed)

## Recording Flow (recommended)

Use the **observe** window as your main screen. Keep focus on one pane at a time.

### 1) Start controlled producer load

```bash
./scripts/03-start-load.sh
```

### 2) Prove lag is not visible yet (no consumer group)

```bash
./scripts/05-watch-lag.sh
```

You should see a clear message that the consumer group is not found.

### 3) Start the consumer group

```bash
./scripts/04-start-consumer.sh
```

### 4) Watch lag trend (grow, then stabilize)

Keep `./scripts/05-watch-lag.sh` running.

### 5) Confirm consumer group health (assigned and running)

```bash
./scripts/06-show-consumer-state.sh
```

### 6) Correlate lag with broker load (proof signal)

```bash
./scripts/07-watch-broker-load.sh
```

## Stop

```bash
./stop-demo.sh
```
