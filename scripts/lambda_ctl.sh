#!/bin/bash

# Script for creating Zebrium CloudWatch logs lambda function

PROG=${0##*/}
TOPDIR=$(dirname $0)/..

usage() {
    echo "Create function:" 1>&2
    echo "$PROG -a -f <lambda_function_name> -r <iam_role> -t <log_collector_token> -u <log_collector_url> -D <deployment_name" 1>&2
    echo "Delete function:" 1>&2
    echo "$PROG -d -f <lambda_function_name>" 1>&2
    exit 1
}

usage_err() {
    echo "$*" 1>&2
    echo "Usage:" 1>&2
    usage
}

err_exit() {
    echo "$*" 1>&2
    exit
}

main() {
    local DEPLOYMENT_NAME=""
    local URL=""
    local TOKEN=""
    local ROLE=""
    local FUNC_NAME=""
    local CREATE_FUNC=false
    local DEL_FUNC=false
    while getopts "adD:f:r:t:u:" OPT; do
        case $OPT in
            a)
                CREATE_FUNC=true
                ;;
            d)
                DEL_FUNC=true
                ;;
            D)
                DEPLOYMENT_NAME=$OPTARG
                ;;
            f)
                FUNC_NAME=$OPTARG
                ;;
            r)
                ROLE=$OPTARG
                ;;
            t)
                TOKEN=$OPTARG
                ;;
            u)
                URL=$OPTARG
                ;;
            *)
                usage
        esac
    done

    if ! $CREATE_FUNC && ! $DEL_FUNC; then
        usage
    fi
    if $CREATE_FUNC && $DEL_FUNC; then
        usage
    fi
    [ -n "$FUNC_NAME" ] || usage_err "Lambda function name is required"
    [ -n "$DEPLOYMENT_NAME" ] || usage_err "Deployment name is required"

    if $CREATE_FUNC; then
        [ -n "$ROLE" ] || usage_err "Lambda role name is required"
        [ -n "$URL" ] || usage_err "Zebrium log collector URL is required"
        [ -n "$TOKEN" ] || usage_err "Zebrium log collector token is required"
        local ARN=`aws lambda create-function \
                                  --function-name $FUNC_NAME \
                                  --role $ROLE \
                                  --runtime nodejs12.x \
                                  --handler index.handler \
                                  --zip-file fileb://$TOPDIR/pkgs/zebrium_cloudwatch-1.0.zip \
                                  --environment "Variables={ZE_DEPLOYMENT_NAME=$DEPLOYMENT_NAME,ZE_LOG_COLLECTOR_URL=$URL,ZE_LOG_COLLECTOR_TOKEN=$TOKEN}" \
                                  --publish |
       awk '/FunctionArn/ { print $2 }' | sed 's/,//'`
       echo "ARN=$ARN"
       if [ -z "$ARN" ]; then
           err_exit "Failed to create lambda function"
       fi
    else
        aws lambda delete-function --function-name $FUNC_NAME
    fi
}

main "$@"
