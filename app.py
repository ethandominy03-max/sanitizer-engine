import csv
import json
from datetime import datetime
from kafka import KafkaProducer

# Read CSV
def read_csv(file_path):
    with open(file_path, mode='r') as file:
        reader = csv.DictReader(file)
        return list(reader)

# Simulated job_request
job_request = []

def insert_job(data):
    job_request.append({
        "file_name": "sample.csv",
        "rows": data
    })

def get_job():
    if job_request:
        return job_request.pop(0)
    return None

# Build JSON
def build_payload(job):
    return {
        "metadata": {
            "user": "your_username",
            "timestamp": datetime.utcnow().isoformat(),
            "source": "vm"
        },
        "file_content": job["rows"]
    }

# Send to Kafka
def send_to_kafka(payload):
    producer = KafkaProducer(
        bootstrap_servers='localhost:9092',
        value_serializer=lambda v: json.dumps(v).encode('utf-8')
    )
    producer.send('sanitizer_in', payload)
    producer.flush()
    print("Sent to Kafka")

# Main
if __name__ == "__main__":
    data = read_csv("sample.csv")
    insert_job(data)
    job = get_job()

    if job:
        payload = build_payload(job)
        print(json.dumps(payload, indent=2))
        send_to_kafka(payload)
    else:
        print("No job found")
