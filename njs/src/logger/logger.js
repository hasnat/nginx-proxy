
// globalThis.window.init();
//import 'cloudkit.js';
var fetch = ngx.fetch;
// var crypto = require('crypto')

// import '../../libs/jsencrypt.js';

function prepare_log_cloudkit(r) {
    var data = {
        operationType : "create",
        record : {
        recordType : "NginxProxyHit",
            fields : {
                headers: {value: JSON.stringify(r.headersIn)},
                ja3: {value: r.variables.ja3},
                ja3_hash: {value: r.variables.ja3_hash},
                time_local: {value: r.variables.time_local},
                scheme: {value: r.variables.scheme},
                method: {value: r.variables.method},
                status: {value: parseInt(r.variables.status)},
                request_uri: {value: r.variables.request_uri},
                request_length: {value: parseInt(r.variables.request_length)},
                request_time: {value: parseFloat(r.variables.request_time)},
                bytes_sent: {value: parseInt(r.variables.bytes_sent)},
                body_bytes_sent: {value: parseInt(r.variables.body_bytes_sent)},
                upstream_addr: {value: r.variables.upstream_addr},
                upstream_status: {value: parseInt(r.variables.upstream_status)},
                upstream_response_time: {value: parseFloat(r.variables.upstream_response_time)},
                upstream_connect_time: {value: parseFloat(r.variables.upstream_connect_time)},
                upstream_header_time: {value: parseFloat(r.variables.upstream_header_time)},
                remote_addr: {value: r.variables.remote_addr},
                remote_user: {value: r.variables.remote_user},
                request_id: {value: r.variables.request_id}
            },
            recordName : r.variables.host + '->' + r.variables.server_name + ' (' + r.variables.request_id + ')'
        },
    }

    return data;
}
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
        upstream_http_name: r.variables.upstream_http_name,
        upstream_trailer_name: r.variables.upstream_trailer_name,
        upstream_status: r.variables.upstream_status,
        upstream_queue_time: r.variables.upstream_queue_time,
        upstream_response_time: r.variables.upstream_response_time,
        upstream_response_length: r.variables.upstream_response_length,
        upstream_connect_time: r.variables.upstream_connect_time,
        upstream_header_time: r.variables.upstream_header_time,
        upstream_cache_status: r.variables.upstream_cache_status,
        upstream_bytes_sent: r.variables.upstream_bytes_sent,
        upstream_bytes_received: r.variables.upstream_bytes_received,
        remote_addr: r.variables.remote_addr,
        remote_user: r.variables.remote_user
    };
}
function headers_log_with_callback(r) {
    // return 'okok';
    var callback = ''
    try {

         callback = /([a-zA-Z0-9_-]{1,})/.exec(r.variables.arg_callback)[0]


    }catch(e){
        r.log('eee')
        // r.log('erroooor-s '+ JSON.stringify(e))
        // r.log('errooe3')
    }

    if (callback != '') {
        r.return(200,callback+'('+headers_log(r)+')')
        // return ;
    } else {
        r.return(200,headers_log(r) + '\n // you can pass callback as /..script.js?callback=myCallback');
    }
}
function headers_log(r) {
    return JSON.stringify(prepare_log(r));
}
function base64ToBinary(base64) {
    var binary_string =  atob(base64);
    var len = binary_string.length;
    var bytes = new Uint8Array( len );
    for (var i = 0; i < len; i++)        {
        bytes[i] = binary_string.charCodeAt(i);
    }
    return bytes;
}
function binaryToBase64URL(int8Array) {
    return btoa(String.fromCharCode.apply(null, int8Array))
        .replace(/\+/g, '-').replace(/\//g, '_')  // URL friendly
        .replace(/\=+$/, '');  // No padding.
}
function b642ab(base64_string){
    return Uint8Array.from(atob(base64_string), function(c) {return c.charCodeAt(0)});
}
function cloudkit_headers_js_content_callback(r) {
    return async function(res) {
        // let reply = await ngx.fetch('http://nginx.org/');
        let text = await res.text();
        njs.dump(res)
        r.return(200, 'pl'+text);
        r.error('key8')
        r.error( njs.dump(res))
        r.error(text)

        r.error('key9')
    }
}
async function cloudkit_headers_js_content(r) {
    return await cloudkit_prepare(r, 'hit');
}
async function cloudkit_headers_log(r) {
    return await cloudkit_prepare(r, 'log');
}
async function cloudkit_prepare(r, request_type) {
    // const JSEncrypt = (await import('../../libs/jsencrypt.min.js')).default;
    r.error('cloudkit_preparsse')
    r.error(request_type)
    r.error('cloudkit_preparee')
    if (request_type == 'log') {
        r.error('request type is log, not doing anything')
        return;
    }

    try {
    // var data = prepare_log(r);
    // data.headers = JSON.stringify(data.headers);
    // [Current date]:[Request body]:[Web service URL subpath]
    const dataString = JSON.stringify(prepare_log_cloudkit(r))
    r.error('cloudkit_prepared dataString: '+ dataString)
    const textEncoder = new TextEncoder('utf-8')
    const textDecoder = new TextDecoder('utf-8')
    // const dataStringBuffer = textEncoder.encode(dataString)


    const dateIso = (new Date()).toISOString().split('.')[0]+'Z';
        r.error('dateIso')
        r.error(dateIso)

    let privateKey = b642ab(process.env.CLOUDKIT_SKEY)
    let key = await crypto.subtle.importKey(
        'pkcs8',
        privateKey,
        {
            name: 'ECDSA',
            namedCurve: 'P-256',
        },
        false,
        ['sign']
    );
    // const key = await crypto.subtle.importKey(
    //     "raw",
    //     new TextEncoder().encode(),
    //     {   //these are the algorithm options
    //         name: "ECDSA",
    //         namedCurve: "P-256", //can be "P-256", "P-384", or "P-521"
    //     },
    //     false,
    //     []
    // )
        r.error('key')
        r.error(key)
        r.error(dataString)
    const path = '/database/1/iCloud.base-container/development/public/records/modify';
        // const dataSha256Digest = await crypto.subtle.digest('SHA-256',  textEncoder.encode(dataString))
        // const dataSha256Digest = await crypto.subtle.digest('SHA-256',  btoa(dataString))
        const dataSha256Digest = await crypto.subtle.digest('SHA-256',  (dataString))
        const dataSha256DigestStr = Buffer.from(dataSha256Digest).toString('base64')
        r.error('key3')

        r.error(dataSha256DigestStr)
        // const dataDigestBase64 = (dataSha256DigestStr);
        const dataDigestBase64 = (dataSha256DigestStr);
        r.error('key4')
        r.error(dataDigestBase64)
        r.error(`${dateIso}:${dataDigestBase64}:${path}`)
        // r.error(textDecoder.decode(dataSha256Digest))
        const sign = crypto.createSign('RSA-SHA256');
        sign.update(`${dateIso}:${dataDigestBase64}:${path}`);
        sign.sign(privateKey, 'base64');
    const signatureBuffer = await crypto.subtle.sign(
        {
            name: "ECDSA",
            hash: "SHA-256", //can be "SHA-1", "SHA-256", "SHA-384", or "SHA-512"
        },
        key,
        `${dateIso}:${dataDigestBase64}:${path}`
    )
    // btoa(hashedData)))
    r.error('key5')
    const signature = (Buffer.from(signatureBuffer).toString('base64'))
    // const signature = (signatureBuffer.toString())
        r.error(btoa(dataString))
        r.error('key6')
        r.error(signature)
    r.error(dateIso)
    r.error(`http://api.apple-cloudkit.com${path}`)
try {
    r.error('key7')
        const fetch_args = [

    ]
    if (request_type == 'hit') {
        fetch_args.push(cloudkit_headers_js_content_callback)
    }
    // const url = `https://enqigcve59uz9.x.pipedream.net${path}`
    const url = `http://api.apple-cloudkit.com${path}`
    // fetch_args[0] = 'https://hasn.at/'
    var logged = await ngx.fetch(url,
        {
            detached: request_type === 'log', // detached=true => I don't want to see/wait for return
            method: 'POST',
            headers: {
                'Content-Type': 'text/plain',
                'X-Apple-CloudKit-Request-SignatureV1': signature,
                'X-Apple-CloudKit-Request-KeyID': process.env.CLOUDKIT_KEYID,
                'X-Apple-CloudKit-Request-ISO8601Date': dateIso
            },
            body: dataString
        });
            let text = await logged.text();
            r.error(`${dateIso}:${dataDigestBase64}:${path}`)
            r.headersOut['Content-Type'] = "text/plain; charset=utf-8";
            r.return(200, 'pl' + text);

        } catch(e) {
            r.error('Error preparing fetch (encryption and all)')
            r.error(njs.dump(e))
            r.error(njs.dump(e.stack))
        }
    // r.error();
        //return JSON.stringify(prepare_log_cloudkit(r))
        r.error('allok')
        r.return(200,'okok')
    return 'OKOKOK';
} catch(e) {
        r.error('Errored preparing request to cloudkit')
        r.error(e)
        throw e
    }
}
function headers_and_body_log(r) {
    r.error('headers_logheaders_and_body_log')
    var log = prepare_log(r);
    // log.body = r.requestBody;
    r.error(JSON.stringify(log));
    return JSON.stringify(log)
}
export default {headers_log, headers_log_with_callback, headers_and_body_log, cloudkit_headers_log, cloudkit_headers_js_content}