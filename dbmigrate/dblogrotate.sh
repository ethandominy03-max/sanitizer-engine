cat << 'EOF' > dblogrotate.sh
#!/bin/bash
LOG_FILE="./dbmigrate.log"
if [ -f "$LOG_FILE" ]; then
    mv "$LOG_FILE" "${LOG_FILE}_$(date +%Y%m%d_%H%M%S)"
    touch "$LOG_FILE"
    echo "Log rotated."
fi
EOF
chmod +x dblogrotate.sh
