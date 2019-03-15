#!/bin/bash

case "$1" in
	h | --help)
        echo "Usage: k8s-pod-checker APP_NAME GIT_VERSION NAMESPACE"
        exit 0
        ;;
esac
    
set -eu

readonly SLEEP=10
readonly TRIES=20
APP=$1
GIT_VERSION=$2
NAMESPACE=$3
COUNT=1
K8SCOMMAND="/usr/local/bin/kubectl get pods -L app,git_version -l app=${APP},git_version=${GIT_VERSION} --namespace ${NAMESPACE} --no-headers"

echo "checking running ${APP}:${GIT_VERSION}"

while [ $COUNT -le $TRIES ];
do
    sleep ${SLEEP}s
    echo "Attempting ${COUNT} try..."
    result=`$K8SCOMMAND`
    echo "$result"
    if [[ -z "$result" ]]; then
        echo "can not find target ${APP}:${GIT_VERSION}"
        exit 1
    fi
    target_pods=$(echo "$result" | wc -l)
    running_pods=$(echo "$result" | grep Running | wc -l)
    if (( target_pods == running_pods )); then
        echo "found ${running_pods} ${APP}:${GIT_VERSION} running"
        exit 0
    fi
    COUNT=`expr $COUNT + 1`
done

echo "Max attempt(${COUNT}) exceed! ${APP}:${GIT_VERSION} is not running"
exit 1
