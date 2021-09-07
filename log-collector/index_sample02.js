// Zebrium Lambda function for AWS Cloudwatch
const agent = require('agentkeepalive');
const asyncRetry = require('async').retry;
const request = require('request');
const zlib = require('zlib');

const MAX_REQUEST_TIMEOUT_MS = 20000;
const FREE_SOCKET_TIMEOUT_MS = 200000;
const DEFAULT_DEPLOYMENT_NAME = "default";
const ZAPI_URL = process.env.ZE_LOG_COLLECTOR_URL;
const MAX_REQUEST_RETRIES = parseInt(process.env.ZE_MAX_REQUEST_RETRIES) || 8;
const REQUEST_RETRY_INTERVAL_MS = parseInt(process.env.ZE_REQUEST_RETRY_INTERVAL) || 200;
const DEFAULT_HTTP_ERRORS = [
    'ECONNRESET'
    , 'EHOSTUNREACH'
    , 'ETIMEDOUT'
    , 'ESOCKETTIMEDOUT'
    , 'ECONNREFUSED'
    , 'ENOTFOUND'];

const INTERNAL_SERVER_ERROR = 500;

// Get Zebrium log collector configurable settings from Environment Variables
const getConfig = () => {
    const pkg = require('./package.json');
    let config = {
        Version: `${pkg.version}` + "-cloudwatch"
    };

    if (process.env.ZE_LOG_COLLECTOR_TOKEN) {
        config.token = process.env.ZE_LOG_COLLECTOR_TOKEN;
    }
    if (!process.env.ZE_DEPLOYMENT_NAME || 0 === process.env.ZE_DEPLOYMENT_NAME.length) {
        config.ze_deployment_name = DEFAULT_DEPLOYMENT_NAME;
    } else {
        config.ze_deployment_name = process.env.ZE_DEPLOYMENT_NAME;
    }
    if (process.env.ZE_HOST) {
        config.ze_hostname = process.env.ZE_HOST;
    }
    if (process.env.ZE_HOST_TAGS && process.env.ZE_HOST_TAGS.length > 0) {
        config.ze_host_tags = process.env.ZE_HOST_TAGS.split(',').map(tag => tag.trim()).join(',');
    }

    return config;
};

// Parse events from Cloudwatch
const getEventData = (event) => {
    return JSON.parse(zlib.unzipSync(Buffer.from(event.awslogs.data, 'base64')));
};

// Prepare the Messages and Options
const getLogMsgEntries = (eventData, config) => {
    return eventData.logEvents.map((event) => {
        return {
            message: event.message,
            id: event.id,
            timestamp: event.timestamp
        };
    });
};

// Prepare the meta data
const getMetaData = (eventData, config) => {
    const deployment_name = config.ze_deployment_name || DEFAULT_DEPLOYMENT_NAME

    // logStream is the ec2 instanceId (hostname) with the i- prefix. The first dash needs to be removed
    // logGroup is the logbasename (lbn) e.g. messages
    const hostname = config.ze_hostname || eventData.logStream.replace( /-/, "" );
    var lbn = eventData.logGroup;

    var ids = {};
    ids['ze_deployment_name'] = deployment_name;
    ids['host'] = hostname;
    ids['log_group'] = eventData.logGroup;
    ids['log_stream'] = eventData.logStream;
    ids['app'] = eventData.lbn;
    var meta_data ={};
    meta_data['stream'] = "native";
    meta_data['logbasename'] = lbn;
    meta_data['user_logbasename'] = true;
    meta_data['container_log'] = false;
    meta_data['ze_log_collector_vers'] = config.Version;
    meta_data['ids'] = ids;
    meta_data['cfgs'] = {};
    meta_data['tags'] = {};

    return meta_data;
};

// Send logs to ZAPI server
const sendLogs = (payload, meta_data, config, callback) => {
    if (!config.token) return callback('Missing Zebrium Auth Token');

    const options = {
        url: ZAPI_URL + "/api/v2/cwpost",
        method: 'POST',
        body: JSON.stringify({
            'meta_data': meta_data,
            'log_data': payload
        }),
        strictSSL: false,
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Token ' + config.token
        },
        timeout: MAX_REQUEST_TIMEOUT_MS,
        withCredentials: false,
        agent: new agent.HttpsAgent({
            freeSocketTimeout: FREE_SOCKET_TIMEOUT_MS
        })
    };

    asyncRetry({
        times: MAX_REQUEST_RETRIES
        , interval: (retryCount) => {
            return REQUEST_RETRY_INTERVAL_MS * Math.pow(2, retryCount);
        }
        , errorFilter: (errCode) => {
            return DEFAULT_HTTP_ERRORS.includes(errCode) || errCode === 'INTERNAL_SERVER_ERROR';
        }
    }, (reqCallback) => {
        return request(options, (error, response, body) => {
            if (error) {
                return reqCallback(error.code);
            }
            if (response.statusCode >= INTERNAL_SERVER_ERROR) {
                return reqCallback('INTERNAL_SERVER_ERROR');
            }
            return reqCallback(null, body);
        });
    }, (error, result) => {
        if (error) return callback(error);
        return callback(null, result);
    });
};

exports.handler = (event, context, callback) => {
    const config = getConfig();
    const eventData = getEventData(event);
    const meta_data = getMetaData(eventData, config);
    return sendLogs(getLogMsgEntries(eventData, config), meta_data, config, callback);
};
