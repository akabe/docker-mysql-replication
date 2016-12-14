#!/bin/bash

set -eu

sleep 10 # Wait MySQL master

REPL_SLAVE_HOST=localhost
REPL_SLAVE_PORT=3306
REPL_SLAVE_USER=root
REPL_SLAVE_PASSWORD=''

REPLICATION_USER=$REPL_MASTER_USER
REPLICATION_PASSWORD=$REPL_MASTER_PASSWORD

REPL_MASTER_LOG=$(mysql \
                      --host=$REPL_MASTER_HOST --port=$REPL_MASTER_PORT \
                      --user=$REPL_MASTER_USER --password=$REPL_MASTER_PASSWORD \
                      --skip-column-names \
                      -e 'show master status')
REPL_MASTER_LOG_FP=( $REPL_MASTER_LOG )
REPL_MASTER_LOG_FILE="${REPL_MASTER_LOG_FP[0]}"
REPL_MASTER_LOG_POS="${REPL_MASTER_LOG_FP[1]}"

echo "Replication: file=$REPL_MASTER_LOG_FILE, pos=$REPL_MASTER_LOG_POS"

mysqldump --host=$REPL_MASTER_HOST --port=$REPL_MASTER_PORT \
          --user=$REPL_MASTER_USER --password=$REPL_MASTER_PASSWORD \
          --master-data=2 \
          --hex-blob \
          --default-character-set=utf8 \
          --all-databases \
          --single-transaction \
| mysql --host=$REPL_SLAVE_HOST --port=$REPL_SLAVE_PORT \
        --user=$REPL_SLAVE_USER --password=$REPL_SLAVE_PASSWORD

mysql --host=$REPL_SLAVE_HOST --port=$REPL_SLAVE_PORT \
      --user=$REPL_SLAVE_USER --password=$REPL_SLAVE_PASSWORD \
      -e "
CHANGE MASTER TO
  MASTER_HOST='$REPL_MASTER_HOST',
  MASTER_USER='$REPL_MASTER_USER',
  MASTER_PASSWORD='$REPL_MASTER_PASSWORD',
  MASTER_LOG_FILE='$REPL_MASTER_LOG_FILE',
  MASTER_LOG_POS=$REPL_MASTER_LOG_POS;
START SLAVE;"

set +eu
