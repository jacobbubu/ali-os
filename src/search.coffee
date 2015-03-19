crypto      = require 'crypto'
jsonist     = require 'jsonist'
qs          = require 'querystring'

BASE_URI = 'http://opensearch.aliyuncs.com'
INDEX_URI = BASE_URI + '/index'
DOC_URI = INDEX_URI + '/doc'
SEARCH_URI = BASE_URI + '/search'
VERSION = 'v2'
SIGNATURE_METHOD = 'HMAC-SHA1'
SIGNATURE_VERSION = '1.0'

clone = (obj) ->
    if not obj? or typeof obj isnt 'object'
        return obj

    if obj instanceof Date
        return new Date(obj.getTime())

    if obj instanceof RegExp
        flags = ''
        flags += 'g' if obj.global?
        flags += 'i' if obj.ignoreCase?
        flags += 'm' if obj.multiline?
        flags += 'y' if obj.sticky?
        return new RegExp(obj.source, flags)

    newInstance = new obj.constructor()

    for key of obj
        newInstance[key] = clone obj[key]

    newInstance

shallowCopyWithoutItems = (obj) ->
    if not obj? or typeof obj isnt 'object'
        return obj

    if obj instanceof Date
        return new Date(obj.getTime())

    if obj instanceof RegExp
        flags = ''
        flags += 'g' if obj.global?
        flags += 'i' if obj.ignoreCase?
        flags += 'm' if obj.multiline?
        flags += 'y' if obj.sticky?
        return new RegExp(obj.source, flags)

    newInstance = new obj.constructor()
    skipItems = obj.sign_mode is '1'
    for k, v of obj
        if not (skipItems and k is 'items')
            newInstance[k] = v

    newInstance

encode = (s) ->
    encodeURIComponent(s).replace /\+/g, '%20'
        .replace /\!/g, '%21'
        .replace /\'/g, '%27'
        .replace /\(/g, '%28'
        .replace /\)/g, '%29'
        .replace /\*/g, '%2A'
        .replace /\~/g, '%7E'

nonce = ->
    +new Date + Math.random().toString()[-4..]

utcNow = ->
    pad2 = (n) ->
        ('0' + n)[-2..]

    d = new Date()
    YY = d.getUTCFullYear()
    MM = pad2 d.getUTCMonth() + 1
    DD = pad2 d.getUTCDate()
    hh = pad2 d.getUTCHours()
    mm = pad2 d.getUTCMinutes()
    ss = pad2 d.getUTCSeconds()
    YY + '-' +
        MM + '-' +
        DD + 'T' +
        hh + ':' +
        mm + ':' +
        ss + 'Z'

module.exports = (opt) ->
    throw 'access key required' if not opt?.accessKey?
    throw 'access secret required' if not opt?.accessSecret?

    { accessKey, accessSecret } = opt

    makeSignature = (method, query) ->
        query.sign_mode = '1'
        signedQs = shallowCopyWithoutItems query
        signedQs.Version = VERSION
        signedQs.AccessKeyId = accessKey
        signedQs.SignatureMethod = SIGNATURE_METHOD
        signedQs.SignatureVersion = SIGNATURE_VERSION
        signedQs.SignatureNonce = nonce()
        signedQs.Timestamp = utcNow()

        stringToSign = ( encode(k) + '=' + encode(v) for k, v of signedQs).sort().join '&'
        hmac = crypto.createHmac 'sha1', accessSecret + '&'
        hmac.update method + '&%2F&' + encodeURIComponent stringToSign
        signedQs.Signature = hmac.digest 'base64'
        signedQs

    httpRequest = (uri, method, query, cb) ->
        signedQs = makeSignature method, query
        endpoint = uri + qs.stringify signedQs
        switch method
            when 'GET'
                jsonist.get endpoint, cb
            when 'POST'
                if query.items?
                    options =
                        headers:
                            'content-type': 'application/x-www-form-urlencoded;charset=utf-8'

                    postData = qs.stringify { items: query.items }
                    jsonist.post endpoint, postData, options, cb
                else
                    cb()

    api =
        app:
            list: (page, pageSize, cb) ->
                query =
                    page: page ? 0
                    page_size: pageSize ? 10
                uri = INDEX_URI + '?'
                httpRequest uri, 'GET', query, cb

            create: (appName, template, cb) ->
                query =
                    action: 'create'
                    template: template
                uri = INDEX_URI + '/' + encodeURIComponent(appName) + '?'
                httpRequest uri, 'GET', query, cb

            status: (appName, cb) ->
                query =
                    action: 'status'
                uri = INDEX_URI + '/' + encodeURIComponent(appName) + '?'
                httpRequest uri, 'GET', query, cb

            delete: (appName, cb) ->
                query =
                    action: 'delete'
                uri = INDEX_URI + '/' + encodeURIComponent(appName) + '?'
                httpRequest uri, 'GET', query, cb
        pushDocs: (appName, tableName, data, cb) ->
            query =
                action: 'push'
                table_name: encodeURIComponent tableName
                items: JSON.stringify data
            uri = DOC_URI + '/' + encodeURIComponent(appName) + '?'
            httpRequest uri, 'POST', query, cb

        # appNames: semicolon delimited application names
        # props: all optional properties metioned by
        # http://docs.aliyun.com/?spm=5176.100054.3.8.98pOTs#/opensearch/api-reference/api-interface&search-related

        search: (props, cb) ->
            uri = SEARCH_URI + '?'
            httpRequest uri, 'GET', props, cb