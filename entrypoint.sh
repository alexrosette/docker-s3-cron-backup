#!/usr/bin/env sh

set -e

cat << EOF > /root/.env
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}
export BACKUP_NAME=${BACKUP_NAME}
export BACKUP_MODE=${BACKUP_MODE}
export TARGET=${TARGET}
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
export S3_BUCKET_URL=${S3_BUCKET_URL}
export S3_STORAGE_CLASS=${S3_STORAGE_CLASS}
export S3_ENDPOINT=${S3_ENDPOINT}
export WEBHOOK_URL=${WEBHOOK_URL}
export PG_CONTAINER=${PG_CONTAINER}
export PG_USER=${PG_USER}
export PG_DATABASE=${PG_DATABASE}
export PG_PASSWORD=${PG_PASSWORD}
EOF

echo "creating crontab"
printf "${CRON_SCHEDULE} /dobackup.sh\n" > /tmp/crontab
crontab - < /tmp/crontab

echo "starting $@"
exec "$@"
