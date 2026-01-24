# Operate and Monitor Kafka Clusters — Companion Code

**Pluralsight course:** *Operate and Monitor Kafka Clusters*  
**Author:** Rupesh Tiwari  
**Level:** Practitioner • **Length:** ~90 minutes  
**Outline approved:** 2025-11-21  
**Skill path:** Build and Monitor Data Pipelines with Apache Kafka (Placement #6)

This repository contains the **hands-on demo environments, scripts, dashboards, and supporting assets** used throughout the course. Each demo is **repeatable** and **operator-focused**—you’ll practice the same workflows platform teams and SREs use to keep Kafka reliable in production.

---

## Who this repo is for

Designed for **data engineers, platform engineers, and SREs** who already know Kafka fundamentals (topics, partitions, offsets, brokers) and want practical skills to:

- Operate brokers and replicas safely
- Monitor lag/ISR/throughput/latency using CLI + dashboards
- Scale partitions/brokers and validate outcomes
- Troubleshoot incidents using logs + metrics
- Apply recovery actions (broker restart, offset reset) safely

---

## Prerequisites

You’ll run the demos locally using containers.

### Required
- **Docker Desktop** (Mac/Windows) or **Docker Engine** (Linux)
- **Docker Compose** (via `docker compose`)

Verify:
```bash
docker --version
docker compose version
```

### Recommended

* **tmux** (some demos are easiest in a 3-pane layout)

Verify:

```bash
tmux -V
```

### Ports used by monitoring demos

* Grafana: [http://localhost:3000](http://localhost:3000)
* Prometheus: [http://localhost:9090](http://localhost:9090)

---

## Tech stack used in the demos

* Docker / Docker Compose demo environments
* Kafka CLI tools inside containers
* JMX + Prometheus + Grafana (Module 2+)

> The demos are built for learning and repeatability. The operational behaviors you’ll observe—lag, ISR/URP, leader movement, client retries, recovery tradeoffs—map directly to real production workflows.

---

## Quick start

1. Clone the repo and open a terminal at the repo root
2. Pick a demo from **Modules & Demos**
3. `cd` into that demo folder
4. Follow that demo’s `README.md`

Many demos include helper scripts such as:

* `run-demo.sh` → start environment (often with a tmux layout)
* `stop-demo.sh` → tear down cleanly

If a demo does not include `run-demo.sh`, its README provides the exact `docker compose` commands.

---

## Running multiple demos safely

To avoid container/network conflicts:

* Always stop the current demo before starting another:

  * `./stop-demo.sh` (preferred), or
  * `docker compose down -v` inside the demo folder
* If you hit “container name already in use,” a previous demo is still running.

  * Use `docker ps` to find it and stop it cleanly.

---

## Repository structure

```
.
├── module-1/        # Operating Kafka clusters with best practices
├── module-2/        # Monitoring & scaling patterns (JMX/Prom/Grafana, reassignment)
├── module-3/        # Troubleshooting & maintenance workflows (logs, recovery)
└── shared/          # Shared assets used by multiple demos
```

Each demo folder contains:

* `README.md` with exact steps
* `docker-compose.yml` (or references)
* `scripts/` for repeatable operator actions (create topic, start load, watch lag, verify ISR, etc.)

---

## Course learning objectives (mapped to demos)

### Terminal Objective 1: Operate Kafka clusters with best practices

* Daily operator responsibilities
* Broker/partition/replica relationships
* Causes of lag, under-replication, storage pressure
* How configuration choices impact stability

### Terminal Objective 2: Monitor Kafka health and performance metrics

* Interpret metrics via CLI/JMX/dashboards
* Track lag, ISR, throughput, request latency
* Build actionable dashboards and alerts

### Terminal Objective 3: Scale and tune Kafka for throughput and reliability

* Add partitions/brokers to scale
* Producer/consumer tuning tradeoffs
* Reassign partitions safely and verify stability

### Terminal Objective 4: Troubleshoot and maintain Kafka clusters

* Diagnose lag and rebalances
* Correlate logs with metrics
* Apply corrective actions safely (restart brokers, reset offsets)
* Preventive maintenance practices

---

## Modules & demos (start here)

### Module 1 — Operating Kafka Clusters with Best Practices

* **Inspect Brokers and Metadata Quorum**
  [`module-1/demo-1-inspect-brokers/README.md`](module-1/demo-1-inspect-brokers/README.md)

* **Detect Lag and ISR Changes**
  [`module-1/demo-2-detect-lag/README.md`](module-1/demo-2-detect-lag/README.md)

* **Analyze Storage Pressure Effects**
  [`module-1/demo-3-storage-pressure/README.md`](module-1/demo-3-storage-pressure/README.md)

* **Test Durability Settings Impact**
  [`module-1/demo-4-durability-settings/README.md`](module-1/demo-4-durability-settings/README.md)

* **Tune Producer Throughput Settings**
  [`module-1/demo-5-producer-tuning/README.md`](module-1/demo-5-producer-tuning/README.md)

* **Scale Using More Partitions**
  [`module-1/demo-6-scale-partitions/README.md`](module-1/demo-6-scale-partitions/README.md)

---

### Module 2 — Monitoring and Scaling Kafka with Proven Patterns

* **Read Metrics via JMX and CLI**
  [`module-2/demo-1-read-metrics-jmx-cli/README.md`](module-2/demo-1-read-metrics-jmx-cli/README.md)

* **Build Grafana Dashboards and Alerts**
  [`module-2/demo-2-grafana-dashboards-alerts/README.md`](module-2/demo-2-grafana-dashboards-alerts/README.md)

* **Reassign Partitions Safely**
  [`module-2/demo-3-reassign-scripts/README.md`](module-2/demo-3-reassign-scripts/README.md)

* **Monitor Cluster After Scaling Actions**
  [`module-2/demo-4-verify-after-scaling/README.md`](module-2/demo-4-verify-after-scaling/README.md)

---

### Module 3 — Troubleshooting Kafka with Real-World Techniques

* **Diagnose Lag and Consumer Issues**
  [`module-3/demo-1-m3-diagnose-lag-consumer-issues/README.md`](module-3/demo-1-m3-diagnose-lag-consumer-issues/README.md)

* **Correlate Logs with Metrics**
  [`module-3/demo-2-m3-correlate-logs-metrics/README.md`](module-3/demo-2-m3-correlate-logs-metrics/README.md)

* **Apply Recovery Actions Safely**
  [`module-3/demo-3-m3-apply-recovery-actions-safely/README.md`](module-3/demo-3-m3-apply-recovery-actions-safely/README.md)
  Covers: broker restart with readiness gates, offset reset tradeoffs, and ISR/URP stability verification.

---

## Troubleshooting checklist (common issues)

**Kafka not ready**

* Wait a few seconds after `docker compose up -d`
* Check logs: `docker logs broker1 --tail 100`

**Lag view shows “consumer group not found”**

* Start consumer first (per demo README)
* Wait 2–10 seconds for group join/commit

**Producer stops immediately**

* Some demos support a stop flag for safe shutdown; remove it and rerun load (see demo README)

**Container name conflict**

* Stop the previous demo with `./stop-demo.sh` or `docker compose down -v`

---

## About the author

**Rupesh Tiwari**
Senior Customer Solutions Manager – Amazon Web Services
Pluralsight Author

* [https://fullstackmaster.net](https://fullstackmaster.net)
* [https://fullstackmaster.net/book](https://fullstackmaster.net/book)

---

## Contributing

This repository is intended for learners. You’re welcome to **fork** it and build your own experiments. Suggestions and improvements are welcome via issues.

---
 

## 📜 License

Educational use only.
All demo code is licensed under MIT.

 