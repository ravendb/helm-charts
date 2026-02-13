#!/bin/bash

echo "Waiting for RavenDB to start and registering admin certificate..."

max_attempts=60
attempt=0
sleep_seconds=5

RAVENDB_PID=$(pgrep -f "Raven.Server" | head -n 1)

# We grep for error keywords (error|exception|failed) to detect failures, as the admin-channel command returns 0 even on exceptions
# We basically wait for server to stand up
while [ $attempt -lt $max_attempts ]; do
    # Capture both stdout and stderr
    output=$(/usr/lib/ravendb/server/rvn admin-channel "$RAVENDB_PID" 2>&1 <<EOF
trustClientCert admin-client-certificate /ravendb/certs/admin.client.certificate.pfx
EOF
)

    # Check if output contains error indicators
    if echo "$output" | grep -qi "error\|exception\|failed"; then
        echo "Registration failed: $output"
    else
        echo "Admin client certificate registered successfully!"
        exit 0
    fi

    echo "Registration failed, waiting ${sleep_seconds}s before retry..."
    cat /tmp/rvn-error.log 2>/dev/null || true
    sleep $sleep_seconds
    attempt=$((attempt + 1))
done

echo "ERROR: Failed to register admin certificate after $max_attempts attempts"
cat /tmp/rvn-error.log 2>/dev/null || true
exit 1

