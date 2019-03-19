#!/usr/bin/env bash

APP_NAME=placid-pies
SERVICE_NAME=placid-pies
#OPENSHIFT_CONSOLE_URL=Set to your OpenShift cluster's Console URL

SCRIPT_DIR=$(cd "$(dirname "$BASH_SOURCE")" ; pwd -P)
OPENSHIFTIO_DIR=${SCRIPT_DIR}/.openshiftio
SOURCE_DIR=${SCRIPT_DIR}
if [[ ! -z "" ]]; then
    SOURCE_DIR=${SOURCE_DIR}/..
    SUB_DIR=/
fi

function do_deploy() {
    PARAMS=""
    REPO_URL=$(git config --get remote.origin.url || echo "")
    if [[ ! -z "${REPO_URL}" ]]; then
        PARAMS="$PARAMS -p=SOURCE_REPOSITORY_URL=${REPO_URL}"
    fi
    if [[ ! -z "${OPENSHIFT_CONSOLE_URL}" ]]; then
        PARAMS="$PARAMS -p=OPENSHIFT_CONSOLE_URL=${OPENSHIFT_CONSOLE_URL}"
    fi
    if [[ -f ${OPENSHIFTIO_DIR}/application.yaml ]]; then
        oc process -f ${OPENSHIFTIO_DIR}/application.yaml --ignore-unknown-parameters ${PARAMS} | oc apply -f -
    fi
    if [[ -f ${OPENSHIFTIO_DIR}/service.welcome.yaml ]]; then
        oc process -f ${OPENSHIFTIO_DIR}/service.welcome.yaml --ignore-unknown-parameters ${PARAMS} | oc apply -f -
    fi
}

function do_build() {
    go get -d ./...
    go build -o gobinary
}

function do_clean() {
    rm ${APP_NAME}
}

function do_push() {
    if [[ "$1" == "--source" || "$1" == "-s" || "$1" == "--binary" || "$1" == "-b" ]]; then
        shift
        oc start-build ${SERVICE_NAME} --from-dir ${SOURCE_DIR} "$@"
    elif [[ "$1" == "--git" || "$1" == "-g" ]]; then
        shift
        oc start-build ${SERVICE_NAME} "$@"
    else
        oc start-build ${SERVICE_NAME} --from-dir ${SOURCE_DIR} "$@"
    fi
}

function do_delete() {
    oc delete all,secrets -l app=${APP_NAME}
}

while [[ $# > 0 ]]; do
    CMD=$1
    shift
    ARGS=()
    while [[ "$1" == -* ]]; do ARGS+=($1); shift; done
    case "$CMD" in
        "deploy")
            do_deploy $ARGS
            ;;
        "build")
            do_build $ARGS
            ;;
        "clean")
            do_clean $ARGS
            ;;
        "push")
            do_push $ARGS
            ;;
        "delete")
            do_delete $ARGS
            ;;
        *)
            echo "Usage: gap [deploy|build|clean|push|delete] ..."
            echo "   deploy  - Deploys the application to OpenShift"
            echo "   build   - Builds the application from code"
            echo "   clean   - Cleans any build artifacts"
            echo "   push    - Pushes code to the application. By default this will push the pe-compiled"
            echo "             binary if it exists, otherwise it will push the local sources to be compiled"
            echo "             on OpenShift. This can be overridden by using one of the following flags:"
            echo "      -b, --binary - Pushes a pre-compiled binary"
            echo "      -s, --source - Pushes the sources"
            echo "      -g, --git    - Reverts to using the sources from Git"
            echo "   delete  - Deletes the application from OpenShift"
        ;;
    esac
    RES=$?
    if [[ $RES > 0 ]]; then
        exit $RES
    fi
done

