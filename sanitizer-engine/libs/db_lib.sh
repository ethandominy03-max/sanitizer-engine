#!/bin/bash
# -------- CORE MYSQL FUNCTION (FORCED DB) --------
run_mysql() {
  local sql="$1"
  # We hardcode the database name right here in the command
  mysql -u "user" -p"password" sanitizer_db -N -s -e "$sql"
}

# ✅ ONLY READ LATEST PENDING JOB
read_latest_job_request() {
  run_mysql "
    SELECT id, COALESCE(file_name, ''), COALESCE(file_content_content_type, ''), REPLACE(TO_BASE64(file_content), '\n', '')
    FROM job_request
    WHERE status = 'PENDING'
    ORDER BY id DESC
    LIMIT 1;
  "
}

# -------- EXECUTION REPORT FUNCTION --------
insert_report() {
  local job_id="$1"
  local status="$2"
  local log="$3"
  run_mysql "
    INSERT INTO job_execution_report (start_time, end_time, execution_node, execution_log, status, job_request_id)
    VALUES (NOW(), NOW(), 'node1', '$log', '$status', $job_id)
    ON DUPLICATE KEY UPDATE 
      end_time = NOW(), 
      execution_log = '$log', 
      status = '$status';
  "
}

# -------- UPDATE STATUS --------
update_job_request_status() {
  local job_id="$1"
  local status="$2"
  run_mysql "UPDATE job_request SET status = '$status' WHERE id = ${job_id};"
}
