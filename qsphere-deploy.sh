#!/bin/bash
# Author: v.stone@163.com

set -ex

CONFIG_FILE=${1?"Config file is required"}
WORKSPACE=".qsphere_workspace"

function check_env
{
    which docker docker-compose || exit 1
    [[ -f $CONFIG_FILE ]] || exit 1
    [[ -d $WORKSPACE ]] && rm -rf $WORKSPACE
    mkdir $WORKSPACE
    return 0
}

function cleanup
{
    [[ -d $WORKSPACE ]] && rm -rf $WORKSPACE
    return 0
}

function generate_compose_yaml
{
    cat <<EOF
version: "3"
services:
  qsphere-db:
    container_name: \${PG_SERVER}
    image: \${IMG_PG}
    restart: always
    environment:
      POSTGRES_DB: \${PG_DB}
      POSTGRES_PASSWORD: \${PG_PASSWORD}
    volumes:
      - \${PG_VOL}:/var/lib/postgresql/data
    command: ["-c", "max_connections=2000"]
  qsphere-svc:
    container_name: \${SVC_NAME}
    image: \${IMG_SVC}
    restart: always
    ports:
      - 6001:6001
    environment:
      PG_DB: \${PG_DB}
      PG_SERVER: \${PG_SERVER}
      PG_PORT: \${PG_PORT}
      PG_USER: \${PG_USER}
      PG_PASSWORD: \${PG_PASSWORD}
    depends_on:
      - \${PG_SERVER}
  qsphere-dashboard:
    container_name: \${DASHBOARD_NAME}
    image: \${IMG_DASHBOARD}
    restart: always
    ports:
      - \${DASHBOARD_PORT}:3000
    environment:
      PG_DB: \${PG_DB}
      PG_SERVER: \${PG_SERVER}
      PG_PORT: \${PG_PORT}
      PG_USER: \${PG_USER}
      PG_PASSWORD: \${PG_PASSWORD}
    depends_on:
      - \${PG_SERVER}
      - \${SVC_NAME}
  qsphere-ui:
    container_name: \${UI_NAME}
    image: \${IMG_UI}
    restart: always
    ports:
      - \${UI_PORT}:80
    depends_on:
      - \${SVC_NAME}
      - \${DASHBOARD_NAME}
EOF
}

function init_workspace
{
    cp $CONFIG_FILE ${WORKSPACE}/.env
    generate_compose_yaml > ${WORKSPACE}/docker-compose.yaml
    return 0
}

function up_qsphere
{
    cd $WORKSPACE
    docker-compose pull
    docker-compose -p qsphere up -d
    docker-compose -p qsphere ps
    cd ..
    return 0
}

# Main
check_env
init_workspace
up_qsphere
cleanup
