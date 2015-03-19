var BASE_URI, DOC_URI, INDEX_URI, SEARCH_URI, SIGNATURE_METHOD, SIGNATURE_VERSION, VERSION, clone, crypto, encode, jsonist, nonce, qs, shallowCopyWithoutItems, utcNow;

crypto = require('crypto');

jsonist = require('jsonist');

qs = require('querystring');

BASE_URI = 'http://opensearch.aliyuncs.com';

INDEX_URI = BASE_URI + '/index';

DOC_URI = INDEX_URI + '/doc';

SEARCH_URI = BASE_URI + '/search';

VERSION = 'v2';

SIGNATURE_METHOD = 'HMAC-SHA1';

SIGNATURE_VERSION = '1.0';

clone = function(obj) {
  var flags, key, newInstance;
  if ((obj == null) || typeof obj !== 'object') {
    return obj;
  }
  if (obj instanceof Date) {
    return new Date(obj.getTime());
  }
  if (obj instanceof RegExp) {
    flags = '';
    if (obj.global != null) {
      flags += 'g';
    }
    if (obj.ignoreCase != null) {
      flags += 'i';
    }
    if (obj.multiline != null) {
      flags += 'm';
    }
    if (obj.sticky != null) {
      flags += 'y';
    }
    return new RegExp(obj.source, flags);
  }
  newInstance = new obj.constructor();
  for (key in obj) {
    newInstance[key] = clone(obj[key]);
  }
  return newInstance;
};

shallowCopyWithoutItems = function(obj) {
  var flags, k, newInstance, skipItems, v;
  if ((obj == null) || typeof obj !== 'object') {
    return obj;
  }
  if (obj instanceof Date) {
    return new Date(obj.getTime());
  }
  if (obj instanceof RegExp) {
    flags = '';
    if (obj.global != null) {
      flags += 'g';
    }
    if (obj.ignoreCase != null) {
      flags += 'i';
    }
    if (obj.multiline != null) {
      flags += 'm';
    }
    if (obj.sticky != null) {
      flags += 'y';
    }
    return new RegExp(obj.source, flags);
  }
  newInstance = new obj.constructor();
  skipItems = obj.sign_mode === '1';
  for (k in obj) {
    v = obj[k];
    if (!(skipItems && k === 'items')) {
      newInstance[k] = v;
    }
  }
  return newInstance;
};

encode = function(s) {
  return encodeURIComponent(s).replace(/\+/g, '%20').replace(/\!/g, '%21').replace(/\'/g, '%27').replace(/\(/g, '%28').replace(/\)/g, '%29').replace(/\*/g, '%2A').replace(/\~/g, '%7E');
};

nonce = function() {
  return +(new Date) + Math.random().toString().slice(-4);
};

utcNow = function() {
  var DD, MM, YY, d, hh, mm, pad2, ss;
  pad2 = function(n) {
    return ('0' + n).slice(-2);
  };
  d = new Date();
  YY = d.getUTCFullYear();
  MM = pad2(d.getUTCMonth() + 1);
  DD = pad2(d.getUTCDate());
  hh = pad2(d.getUTCHours());
  mm = pad2(d.getUTCMinutes());
  ss = pad2(d.getUTCSeconds());
  return YY + '-' + MM + '-' + DD + 'T' + hh + ':' + mm + ':' + ss + 'Z';
};

module.exports = function(opt) {
  var accessKey, accessSecret, api, httpRequest, makeSignature;
  if ((opt != null ? opt.accessKey : void 0) == null) {
    throw 'access key required';
  }
  if ((opt != null ? opt.accessSecret : void 0) == null) {
    throw 'access secret required';
  }
  accessKey = opt.accessKey, accessSecret = opt.accessSecret;
  makeSignature = function(method, query) {
    var hmac, k, signedQs, stringToSign, v;
    query.sign_mode = '1';
    signedQs = shallowCopyWithoutItems(query);
    signedQs.Version = VERSION;
    signedQs.AccessKeyId = accessKey;
    signedQs.SignatureMethod = SIGNATURE_METHOD;
    signedQs.SignatureVersion = SIGNATURE_VERSION;
    signedQs.SignatureNonce = nonce();
    signedQs.Timestamp = utcNow();
    stringToSign = ((function() {
      var results;
      results = [];
      for (k in signedQs) {
        v = signedQs[k];
        results.push(encode(k) + '=' + encode(v));
      }
      return results;
    })()).sort().join('&');
    hmac = crypto.createHmac('sha1', accessSecret + '&');
    hmac.update(method + '&%2F&' + encodeURIComponent(stringToSign));
    signedQs.Signature = hmac.digest('base64');
    return signedQs;
  };
  httpRequest = function(uri, method, query, cb) {
    var endpoint, options, postData, signedQs;
    signedQs = makeSignature(method, query);
    endpoint = uri + qs.stringify(signedQs);
    switch (method) {
      case 'GET':
        return jsonist.get(endpoint, cb);
      case 'POST':
        if (query.items != null) {
          options = {
            headers: {
              'content-type': 'application/x-www-form-urlencoded;charset=utf-8'
            }
          };
          postData = qs.stringify({
            items: query.items
          });
          return jsonist.post(endpoint, postData, options, cb);
        } else {
          return cb();
        }
    }
  };
  return api = {
    app: {
      list: function(page, pageSize, cb) {
        var query, uri;
        query = {
          page: page != null ? page : 0,
          page_size: pageSize != null ? pageSize : 10
        };
        uri = INDEX_URI + '?';
        return httpRequest(uri, 'GET', query, cb);
      },
      create: function(appName, template, cb) {
        var query, uri;
        query = {
          action: 'create',
          template: template
        };
        uri = INDEX_URI + '/' + encodeURIComponent(appName) + '?';
        return httpRequest(uri, 'GET', query, cb);
      },
      status: function(appName, cb) {
        var query, uri;
        query = {
          action: 'status'
        };
        uri = INDEX_URI + '/' + encodeURIComponent(appName) + '?';
        return httpRequest(uri, 'GET', query, cb);
      },
      "delete": function(appName, cb) {
        var query, uri;
        query = {
          action: 'delete'
        };
        uri = INDEX_URI + '/' + encodeURIComponent(appName) + '?';
        return httpRequest(uri, 'GET', query, cb);
      }
    },
    pushDocs: function(appName, tableName, data, cb) {
      var query, uri;
      query = {
        action: 'push',
        table_name: encodeURIComponent(tableName),
        items: JSON.stringify(data)
      };
      uri = DOC_URI + '/' + encodeURIComponent(appName) + '?';
      return httpRequest(uri, 'POST', query, cb);
    },
    search: function(props, cb) {
      var uri;
      uri = SEARCH_URI + '?';
      return httpRequest(uri, 'GET', props, cb);
    }
  };
};
