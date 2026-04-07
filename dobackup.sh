#!/usr/bin/env sh

set -e

source /root/.env

S3_STORAGE_CLASS=${S3_STORAGE_CLASS:-STANDARD}
BACKUP_MODE=${BACKUP_MODE:-directory}
TARGET=${TARGET:-/data}

TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
FILE_NAME="/tmp/${BACKUP_NAME}-${TIMESTAMP}.tar.gz"

if [ -z "${S3_ENDPOINT}" ]; then
  AWS_ARGS=""
else
  AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
fi

echo "=== Backup started [mode: ${BACKUP_MODE}] ==="

case ${BACKUP_MODE} in
  postgres)
    if [ -z "${PG_CONTAINER}" ] || [ -z "${PG_USER}" ] || [ -z "${PG_DATABASE}" ]; then
      echo "ERROR: PG_CONTAINER, PG_USER and PG_DATABASE are required for postgres mode"
      exit 1
    fi

    DUMP_FILE="/tmp/${BACKUP_NAME}-${TIMESTAMP}.sql"

    echo "creating pg_dump from container ${PG_CONTAINER}"
    if [ -n "${PG_PASSWORD}" ]; then
      docker exec -e PGPASSWORD="${PG_PASSWORD}" "${PG_CONTAINER}" \
        pg_dump -U "${PG_USER}" "${PG_DATABASE}" > "${DUMP_FILE}"
    else
      docker exec "${PG_CONTAINER}" \
        pg_dump -U "${PG_USER}" "${PG_DATABASE}" > "${DUMP_FILE}"
    fi

    echo "compressing dump"
    tar -czf "${FILE_NAME}" -C /tmp "$(basename ${DUMP_FILE})"
    rm "${DUMP_FILE}"
    ;;

  directory)
    if [ ! -d "${TARGET}" ]; then
      echo "ERROR: target directory ${TARGET} does not exist"
      exit 1
    fi

    echo "creating archive of directory ${TARGET}"
    tar -czf "${FILE_NAME}" -C "$(dirname ${TARGET})" "$(basename ${TARGET})"
    ;;

  file)
    if [ ! -f "${TARGET}" ]; then
      echo "ERROR: target file ${TARGET} does not exist"
      exit 1
    fi

    echo "creating archive of file ${TARGET}"
    tar -czf "${FILE_NAME}" -C "$(dirname ${TARGET})" "$(basename ${TARGET})"
    ;;

  *)
    echo "ERROR: unknown BACKUP_MODE '${BACKUP_MODE}'. Use: postgres, directory, file"
    exit 1
    ;;
esac

echo "uploading archive to S3 [${FILE_NAME}, storage class: ${S3_STORAGE_CLASS}]"
aws s3 ${AWS_ARGS} cp --storage-class "${S3_STORAGE_CLASS}" "${FILE_NAME}" "${S3_BUCKET_URL}"

echo "removing local archive"
rm "${FILE_NAME}"

echo "=== Backup completed ==="

if [ -n "${WEBHOOK_URL}" ]; then
  echo "notifying webhook"
  curl -m 10 --retry 5 "${WEBHOOK_URL}"
fi
