function prepare_log(r) {
    return {
        headers: r.headersIn,
        ja3: r.variables.ja3,
        ja3_hash: r.variables.ja3_hash,
        time_local: r.variables.time_local,
        scheme: r.variables.scheme,
        method: r.variables.method,
        status: r.variables.status,
        request_uri: r.variables.request_uri,
        request_length: r.variables.request_length,
        request_time: r.variables.request_time,
        bytes_sent: r.variables.bytes_sent,
        body_bytes_sent: r.variables.body_bytes_sent,
        upstream_addr: r.variables.upstream_addr,
        upstream_status: r.variables.upstream_status,
        upstream_response_time: r.variables.upstream_response_time,
        upstream_connect_time: r.variables.upstream_connect_time,
        upstream_header_time: r.variables.upstream_header_time,
        remote_addr: r.variables.remote_addr,
        remote_user: r.variables.remote_user
    };
}
function headers_log(r) {

    return JSON.stringify(prepare_log(r));
}

function headers_and_body_log(r) {
    var log = prepare_log(r);
    log['body'] = r.requestBody;
    console.log(JSON.stringify(log));
    return JSON.stringify(log)
}
export default {headers_log, headers_and_body_log}