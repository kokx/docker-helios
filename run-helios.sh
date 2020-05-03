#!/bin/bash

# Solution from https://docs.docker.com/config/containers/multi-service_container/

# Start helios itself
env \
    VOTER_UPLOAD_REL_PATH='voters/%Y/%m/%d' \
    python manage.py runserver 0.0.0.0:8000 &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start helios server: $status"
  exit $status
fi

# Start rabbitmq
rabbitmq-server &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start rabbitmq: $status"
  exit $status
fi

# Start the worker
env C_FORCE_ROOT=1 \
    CELERY_ACCEPT_CONTENT=pickle \
        /usr/local/bin/celeryd &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start celery: $status"
  exit $status
fi

# Naive check runs checks once a minute to see if either of the processes exited.
# This illustrates part of the heavy lifting you need to do if you want to run
# more than one service in a container. The container exits with an error
# if it detects that either of the processes has exited.
# Otherwise it loops forever, waking up every 60 seconds

while sleep 60; do
  ps aux |grep python |grep -q -v grep
  PROCESS_1_STATUS=$?
  ps aux |grep celery |grep -q -v grep
  PROCESS_2_STATUS=$?
  # If the greps above find anything, they exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0 ]; then
    echo "One of the processes has already exited."
    exit 1
  fi
done