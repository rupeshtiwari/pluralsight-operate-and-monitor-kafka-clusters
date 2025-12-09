

# Demo 1 – Inspect Kafka Brokers and Replication

Author: **Rupesh Kumar Tiwari**

This demo runs a three broker Apache Kafka cluster on Docker and walks through the basic checks I perform as an operator:

* Start a small multi broker cluster
* Create a replicated topic
* Inspect leaders, replicas and ISR
* Simulate a broker failure and recovery

Everything here is fully reproducible on a laptop.

---

## 1. Prerequisites

Make sure you have:

* Docker Desktop installed and running
* Docker CLI available in your terminal
* Docker Compose v2 (`docker compose`)

I run this from the course repo in:

```text
src/module-1/demo-1-inspect-brokers
```

---

## 2. Folder Layout

This folder contains:

```text
demo-1-inspect-brokers/
  ├── docker-compose.yml
  ├── notes.md
  ├── commands.txt
  └── screenshots/
```

The main file is `docker-compose.yml`.

---

## 3. Docker Compose Configuration

The `docker-compose.yml` defines:

* One ZooKeeper container
* Three Kafka brokers: `broker1`, `broker2`, `broker3`

Key details:

* All brokers connect to ZooKeeper at `zookeeper:2181`
* Each broker exposes its own host port

  * `broker1` – 9092
  * `broker2` – 9093
  * `broker3` – 9094
* Default replication factor is 3
* `min.insync.replicas` is 2

This creates a realistic cluster with three replicas per partition.

---

## 4. Start the Cluster

From the demo folder:

```bash
cd src/module-1/demo-1-inspect-brokers
docker compose up -d
```

Verify all containers are running:

```bash
docker ps
```

Expected output:

```text
CONTAINER ID   IMAGE                             NAMES
a6c63a34465a   confluentinc/cp-kafka:7.5.0       broker2
d44dc1bc3ae4   confluentinc/cp-kafka:7.5.0       broker1
3fe7ba3eee8c   confluentinc/cp-kafka:7.5.0       broker3
21886cbe3321   confluentinc/cp-zookeeper:7.5.0   zookeeper
```

If a container is not up, check logs:

```bash
docker logs broker1 | head -50
docker logs zookeeper | head -50
```

---

## 5. Open a Shell Inside Broker 1

Run all Kafka CLI commands inside `broker1`:

```bash
docker exec -it broker1 bash
```

Prompt should look like:

```text
[appuser@<container-id> ~]$
```

---

## 6. Create a Replicated Topic

Create a topic `demo-topic` with three partitions and replication factor three:

```bash
kafka-topics \
  --bootstrap-server broker1:9092 \
  --create \
  --topic demo-topic \
  --partitions 3 \
  --replication-factor 3
```

Expected:

```text
Created topic demo-topic.
```

If it already exists:

```bash
kafka-topics --bootstrap-server broker1:9092 --delete --topic demo-topic
```

Then recreate it.

---

## 7. Inspect the Healthy Topic Layout

Describe the topic:

```bash
kafka-topics \
  --bootstrap-server broker1:9092 \
  --describe \
  --topic demo-topic
```

Example:

```text
Topic: demo-topic  PartitionCount: 3  ReplicationFactor: 3  Configs: min.insync.replicas=2
  Partition: 0  Leader: 1  Replicas: 1,2,3  Isr: 1,2,3
  Partition: 1  Leader: 2  Replicas: 2,3,1  Isr: 2,3,1
  Partition: 2  Leader: 3  Replicas: 3,1,2  Isr: 3,1,2
```

What I check:

* Replication factor is 3
* Leaders are distributed across brokers
* All partitions have full ISR (1,2,3)

This represents a healthy cluster.

---

## 8. Simulate a Broker Failure

Keep the broker shell open. In a second host terminal:

```bash
cd src/module-1/demo-1-inspect-brokers
docker stop broker2
```

Confirm:

```bash
docker ps
```

`broker2` should be missing while the others stay up.

Back in the `broker1` shell:

```bash
kafka-topics \
  --bootstrap-server broker1:9092 \
  --describe \
  --topic demo-topic
```

Output should show a reduced ISR:

```text
Partition: 0  Leader: 3  Replicas: 3,1,2  Isr: 3,1
Partition: 1  Leader: 1  Replicas: 1,3,2  Isr: 1,3
Partition: 2  Leader: 3  Replicas: 3,1,2  Isr: 3,1
```

Replication factor still shows as 3, but ISR shrinks. This is expected when a broker is down.

---

## 9. Recover the Broker and Confirm ISR

On the host:

```bash
docker start broker2
```

After a few seconds, describe the topic again:

```bash
kafka-topics \
  --bootstrap-server broker1:9092 \
  --describe \
  --topic demo-topic
```

ISR should return to full strength:

```text
Isr: 1,2,3
Isr: 2,3,1
Isr: 3,1,2
```

Exit the container:

```bash
exit
```

Final check:

```bash
docker ps
```

All brokers and ZooKeeper should be up.

---

## 10. Optional Cleanup

To stop and remove everything:

```bash
cd src/module-1/demo-1-inspect-brokers
docker compose down
```

---

## 11. Summary

In this demo you:

1. Started a three broker Kafka cluster on Docker
2. Created a topic with replication factor three
3. Verified leaders, replicas and ISR
4. Stopped a broker and observed ISR shrink
5. Restarted the broker and confirmed full ISR recovery

These checks mirror what a Kafka operator should monitor daily.

For deeper help with Kafka operations or production systems, visit **[https://fullstackmaster.net](https://fullstackmaster.net)** or book a session at **[https://fullstackmaster.net/book](https://fullstackmaster.net/book)**.

---

If you want, I can also help convert this into a video script, slides, or a GitHub friendly version.
