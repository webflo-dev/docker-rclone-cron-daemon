#!/bin/bash

# Run rclone only if the previous cron job finished
(

  flock -n 200 || exit 10

  # Setup a basic rclone command
  job_command="rclone --ask-password=false --config=/config/.rclone.conf --verbose $RCLONE_MODE $RCLONE_SOURCE $RCLONE_DESTINATION"

  # Check if the container is running a customer rclone command, otherwise,
  # ensure a mode, source and destination are provided. If not, bail out.
  if [ -n "$RCLONE_COMMAND" ]; then
    job_command="$RCLONE_COMMAND"
  elif [ -n "$RCLONE_COMMAND" ] && [ "$RCLONE_COMMAND" = "" ]; then
    echo "Error: The container was passed the option to run a custom rclone command but no"
    echo "Error: command was provided."
    exit 11
  else
    if [ -z "$RCLONE_MODE" ]; then
      echo "Error: No rclone mode was specified for job execution"
      exit 12
    elif [ -z "$RCLONE_SOURCE" ] || [ -z "$RCLONE_DESTINATION" ]; then
      echo "Error: Source or Destination options for rclone were not passed to the container."
      exit 13
    elif [ -n "$RCLONE_BANDWIDTH" ]; then
      job_command="rclone --ask-password=false --config=/config/.rclone.conf --verbose $RCLONE_MODE $RCLONE_SOURCE $RCLONE_DESTINATION --bwlimit $RCLONE_BANDWIDTH"
    elif [ -n "$RCLONE_FLAGS" ]; then
      job_command="rclone --ask-password=false --config=/config/.rclone.conf --verbose $RCLONE_MODE $RCLONE_SOURCE $RCLONE_DESTINATION $RCLONE_FLAGS"
    elif [ -n "$RCLONE_BANDWIDTH" ] && [ -n "$RCLONE_FLAGS" ]; then
      if [ -z "$RCLONE_BANDWIDTH" ] || [ -z "$RCLONE_FLAGS" ]; then
        echo "Error: Rclone bandwidth or additional flags option was provided but no values were set."
        exit 14
      else
        job_command="rclone --ask-password=false --config=config/.rclone.conf --verbose $RCLONE_MODE $RCLONE_SOURCE $RCLONE_DESTINATION $RCLONE_FLAGS --bwlimit $RCLONE_BANDWIDTH"
      fi
    fi
  fi

  echo "Info: Executing => $job_command"
  eval "$job_command"

  if [ "$JOB_SUCCESS_URL" ]; then
    echo "Info: Reporting job success to health check endpoint"
    curl -Ss --retry 3 $JOB_SUCCESS_URL > /dev/null
  fi
) 200>/var/lock/rclone.lock
