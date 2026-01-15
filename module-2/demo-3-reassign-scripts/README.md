# Demo 3 — Reassign Partitions Safely (Self-Contained)

Record this demo using **two full-screen terminals**.

## Prereqs (macOS)
- Docker Desktop
- jq installed:
```bash
brew install jq
```

## Start / Stop
```bash
chmod +x run-demo.sh stop-demo.sh scripts/*.sh
./run-demo.sh
```

Stop:
```bash
./stop-demo.sh
```

## Recording flow

### Terminal A (Topic State)
```bash
./scripts/02-create-imbalanced-topic.sh
./scripts/03-describe-topic.sh
```

### Terminal B (Reassignment)
```bash
./scripts/04-generate-plan.sh
./scripts/05-execute-plan.sh
./scripts/06-verify-plan.sh
```

### Terminal A (Proof after)
```bash
./scripts/03-describe-topic.sh
./scripts/07-leader-count.sh
```
