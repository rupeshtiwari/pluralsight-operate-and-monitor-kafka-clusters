# 📘 **Operate and Monitor Kafka Clusters**

### Official Companion Code for the Pluralsight Course by **Rupesh Tiwari**

This repository hosts all the code, configs, scripts, and resources used in the Pluralsight course **Operate and Monitor Kafka Clusters**.

The goal is simple:
Provide a clean, repeatable environment so learners can **practice every operational workflow** taught in the course.

---

# 📑 **Table of Contents**

### **Module 1 – Operating Kafka Clusters with Best Practices**

1. **Inspect Brokers & Metadata Quorum**
   👉 [`module-1/demo-1-inspect-brokers/README.md`](module-1/demo-1-inspect-brokers/README.md)

2. **Detect Lag & Understand Consumer Behavior**
   👉 [`module-1/demo-2-detect-lag/README.md`](module-1/demo-2-detect-lag/README.md)

3. **Analyze Storage Pressure Effects**
   👉 [`module-1/demo-3-storage-pressure/README.md`](module-1/demo-3-storage-pressure/README.md)

4. **Test Durability Settings (acks & replication)**
   👉 [`module-1/demo-4-durability-settings/README.md`](module-1/demo-4-durability-settings/README.md)

5. **Tune Producer Throughput Settings**
   👉 [`module-1/demo-5-producer-tuning/README.md`](module-1/demo-5-producer-tuning/README.md)

6. **Scale Using More Partitions**
   👉 [`module-1/demo-6-scale-partitions/README.md`](module-1/demo-6-scale-partitions/README.md)

---

## 🎯 **Course Overview**

Modern applications rely heavily on Apache Kafka, but operating Kafka safely in production requires deep understanding of:

* Broker and topic health
* Consumer lag and rebalancing
* ISR behavior and replication guarantees
* Leadership distribution and partition balance
* Storage pressure, retention enforcement, and log behavior
* Producer and consumer tuning
* Recovery workflows after failures

Every demo in this repo simulates a **real-world operational scenario** that Kafka engineers face in production.

---

## 📂 **Repository Structure**

```
pluralsight-operate-and-monitor-kafka-clusters/
│
├── code/
│   ├── module-1/
│   │   ├── demo-1-inspect-brokers/
│   │   ├── demo-2-detect-lag/
│   │   ├── demo-3-storage-pressure/
│   │   ├── demo-4-durability-settings/
│   │   ├── demo-5-producer-tuning/
│   │   └── demo-6-scale-partitions/
│   │
│   ├── module-2/   ← coming soon
│   ├── module-3/   ← coming soon
│   └── shared/     ← common scripts, helpers, icons
│
└── README.md   ← You are here
```

Each demo folder contains:

* A **README** with step-by-step instructions
* All scripts used in the Pluralsight video
* `docker-compose.yml`
* Reusable helper scripts
* Expected output or screenshots

---

## 🛠️ **Tech Stack**

This course uses:

* **Apache Kafka 3.x** (KRaft + ZooKeeper variants)
* **Docker Compose** for multi-broker environments
* **kafka-topics**, **kafka-consumer-groups**, **kafka-producer-perf-test**
* **VS Code** + integrated terminal
* **Linux-friendly tools** (watch, awk, bash scripts)

Everything runs cleanly on:

* macOS (Intel + Apple Silicon)
* Windows (WSL2 recommended)
* Linux

---

## 🧩 Prerequisites

To run the demos in this repository, you need:

- Docker Desktop (with Docker Compose v2)
- tmux (for multi-terminal demos)
- Git (recommended)

Installation links and OS-specific instructions are provided inside each demo’s README.

---

## 🚀 **How to Run Any Demo**

Every demo can be executed independently.

```bash
cd code/module-1/demo-1-inspect-brokers
docker compose up -d
```

Then follow the instructions in the corresponding README.

**Tip:**
If you are learning Kafka operations seriously, run each demo *twice* — once following instructions, once improvising failures.

---

## 🧑‍🏫 **About the Author**

**Rupesh Tiwari**
Senior Customer Solutions Manager – Amazon Web Services
Pluralsight Author | Full Stack Master Instructor

🌐 [https://fullstackmaster.net](https://fullstackmaster.net)
🎯 Book 1-on-1 coaching: [https://fullstackmaster.net/book](https://fullstackmaster.net/book)

---

# 📌 **Support & 1:1 Coaching**

If you want deeper help with Kafka production design, scaling, performance tuning, or building full data platforms, join me at:

### **📚 FullStackMaster — Master Kafka & Cloud**

[https://fullstackmaster.net](https://fullstackmaster.net)

### **🎯 Book a private coaching session**

[https://fullstackmaster.net/book](https://fullstackmaster.net/book)

---

## ⭐ **Contributing**

This repository is read-only for learners.
You are welcome to fork it and build your own experiments.
Issues and improvements are always appreciated.

---

## 📜 License

Educational use only.
All demo code is licensed under MIT.

---

### ✔ README updated and ready for GitHub

If you want:

* A **Module 2 TOC template now**,
* A **Course banner or diagram**, or
* A **GitHub Pages docs site**,

I can generate those next.
