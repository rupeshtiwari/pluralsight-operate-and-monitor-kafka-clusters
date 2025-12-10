
# 📘 Operate and Monitor Kafka Clusters

### Official Companion Code for the Pluralsight Course by **Rupesh Tiwari**

This repository contains all demo code, configuration files, and supporting resources used in the Pluralsight course **“Operate and Monitor Kafka Clusters.”**
The goal of this repo is simple: give learners a clean, repeatable environment to practice the operational workflows demonstrated in the course.

---

## 🎯 Course Overview

Modern applications rely heavily on Apache Kafka, but running Kafka in production requires more than just spinning up brokers.
This course teaches you how to:

* Inspect and validate broker health
* Detect and troubleshoot consumer lag
* Confirm replication and ISR stability
* Understand leadership distribution
* Identify storage pressure and bottlenecks
* Validate recovery after failures
* Operate Kafka clusters confidently and safely

Each demo is designed to simulate **real-world operational scenarios** that Kafka engineers encounter daily.

---

## 📂 Repository Structure

```
pluralsight-operate-and-monitor-kafka-clusters/
│
├── src/
│   ├── module-1/
│   │   └── demo-1-inspect-brokers/
│   │       ├── docker-compose.yml
│   │       ├── commands.txt
│   │       └── README.md
│   │
│   ├── module-2/   (coming soon)
│   ├── module-3/   (coming soon)
│   └── shared/
│       └── scripts, helpers, configs
│
└── README.md   ← (you are here)
```

The **`src/module-*`** directories mirror the Pluralsight course modules.
Each demo is fully self-contained and can be run independently.

---

## 🛠️ Tech Stack

This course uses:

* **Apache Kafka (Confluent Platform)** – running in Docker containers
* **ZooKeeper** (for module 1 demos)
* **KRaft mode** (in later modules)
* **VS Code** for CLI + config navigation
* **Docker Compose** for orchestrating multi-broker clusters

Everything works on macOS, Windows, and Linux.

---

## 🚀 How to Run the Demos

Each demo folder includes a **README.md** with:

* Required prerequisites
* Step-by-step instructions
* All CLI commands used in the video
* Expected output screenshots
* Troubleshooting notes

To run any demo:

```bash
cd src/module-1/demo-1-inspect-brokers
docker compose up -d
```

Then follow the commands listed in the demo’s README.

---

## 🧑‍🏫 About the Author

**Rupesh Tiwari**
Senior Customer Solutions Manager – Amazon Web Services
Pluralsight Author | Full Stack Master Instructor

🌐 [https://fullstackmaster.net](https://fullstackmaster.net)
📘 Book a session: [https://fullstackmaster.net/book](https://fullstackmaster.net/book)

---


### 📌 **Support & 1:1 Coaching**

For deeper Kafka help, production design, or performance tuning:

## **📚 FullStackMaster | Master Kafka & Cloud**

[https://fullstackmaster.net](https://fullstackmaster.net)

### **🎯 Book a 1-on-1 Coaching Session**

[https://fullstackmaster.net/book](https://fullstackmaster.net/book)

 ----

## ⭐ Contributing

This repo is read-only for learners, but feel free to fork it if you want to experiment.
Issues and feedback are welcome.

---

## 📜 License

All demo code is provided for educational use under the MIT License.
 