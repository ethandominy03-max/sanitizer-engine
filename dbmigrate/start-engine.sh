cat << 'EOF' > start-engine.sh
#!/bin/bash
DB_HOST="127.0.0.1"
DB_USER="logapp"
DB_PASS="logapp123"
DB_NAME="logdb"
while true; do
    CMD_DATA=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -s -e "SELECT id, message FROM logs WHERE status='pending' LIMIT 1;")
    if [ -n "$CMD_DATA" ]; then
        CMD_ID=$(echo $CMD_DATA | awk '{print $1}')
        PENDING_CMD=$(echo $CMD_DATA | cut -d' ' -f2-)
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "UPDATE logs SET status='processing' WHERE id=$CMD_ID;"
        OUTPUT=$(eval "$PENDING_CMD" 2>&1)
        EXIT_CODE=$?
        CLEAN_OUTPUT=$(echo "$OUTPUT" | sed "s/'/''/g")
        STATUS=$([ $EXIT_CODE -eq 0 ] && echo "done" || echo "error")
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "UPDATE logs SET status='$STATUS' WHERE id=$CMD_ID;"
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "INSERT INTO execution_log (log_id, command, output, exit_code) VALUES ($CMD_ID, '$PENDING_CMD', '$CLEAN_OUTPUT', $EXIT_CODE);"
    fi
    sleep 5
done
EOF
chmod +x start-engine.sh
