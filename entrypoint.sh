#!/usr/bin/env bash

# Exit if user already exists
USERTODEL=$(getent passwd $UNISON_UID | cut -d":" -f1)
if [ -n "$USERTODEL" ] && [ "$USERTODEL" != "$UNISON_USER" ]; then
    echo "User with UID $UNISON_UID already exists: $USERTODEL."
    exit 1
fi

# there is a bug with adding a user to existing group
#addgroup -g $UNISON_GID $UNISON_GROUP
adduser -D -u $UNISON_UID $UNISON_USER

# Create directory for filesync
if [ ! -d "$UNISON_DIR" ]; then
    echo "Creating $UNISON_DIR directory for sync..."
    mkdir -p $UNISON_DIR >> /dev/null 2>&1
fi

# Change data owner
chown -R ${UNISON_USER}. $UNISON_DIR

# Start process on path which we want to sync
cd $UNISON_DIR

# Gracefully stop the process on 'docker stop'
trap 'kill -TERM $PID' TERM INT

# Run unison server as correct user
su -c "unison -socket 5000" $UNISON_USER &

# Wait until the process is stopped
PID=$!
wait $PID
trap - TERM INT
wait $PID
EXIT_STATUS=$?
