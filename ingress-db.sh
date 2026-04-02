#!/bin/bash

# -------- CORE MYSQL FUNCTION (DOCKER VERSION) --------
# This sends the command INTO the running Docker container
run_mysql() {
  local sql="$1"
  docker compose -f /root/sanitizer-engine/dev/docker-compose.yml exec -T db mysql -u user -ppassword sanitizer_db -N -s -e "$sql"
}

# -------- FUNCTIONS --------
read_latest_job_request() {
  run_mysql "SELECT id, COALESCE(file_name, ''), COALESCE(file_content_content_type, ''), REPLACE(TO_BASE64(file_content), '\n', '') FROM job_request WHERE status = 'PENDING' ORDER BY id DESC LIMIT 1;"
}

insert_report() {
  local job_id="$1"
  local status="$2"
  local log="$3"
  run_mysql "INSERT INTO job_execution_report (start_time, end_time, execution_node, execution_log, status, job_request_id) VALUES (NOW(), NOW(), 'node1', '$log', '$status', $job_id) ON DUPLICATE KEY UPDATE end_time = NOW(), execution_log = '$log', status = '$status';"
}

update_job_request_status() {
  local job_id="$1"
  local status="$2"
  run_mysql "UPDATE job_request SET status = '$status' WHERE id = ${job_id};"
}

# -------- MAIN LOGIC --------
echo "[+] Reading latest PENDING job from Docker DB..."
JOB_DATA=$(read_latest_job_request)

if [ -z "$JOB_DATA" ]; then
  echo "[!] No PENDING jobs found. Inserting a test job into Docker..."
  run_mysql "INSERT INTO job_request (file_name, status, file_content, file_content_content_type, file_type, request_type, priority) VALUES ('test_file.txt', 'PENDING', 'SGVsbG8gV29ybGQ=', 'text/plain', 'TEXT', 'SANITIZATION', 1);"
  JOB_DATA=$(read_latest_job_request)
fi

# SAFE PARSING
IFS=$'\t' read -r JOB_ID FILE_NAME CONTENT_TYPE FILE_B64 <<< "$JOB_DATA"

echo "[+] Job ID Found: $JOB_ID"
insert_report "$JOB_ID" "STARTED" "Job started"

# SIMULATE PROCESSING
echo "[+] Processing and sending to Kafka..."
insert_report "$JOB_ID" "PROCESSING" "Decoded and Sent to Kafka"

# COMPLETE
update_job_request_status "$JOB_ID" "COMPLETED"
insert_report "$JOB_ID" "COMPLETED" "Job completed successfully"

echo "[+] SUCCESS: Job execution log updated in the database."
