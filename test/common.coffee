###
    credential.js is ignored from git repo.
    that should be locatied in the test folder with following content

    module.exports = {
        accessKey: 'your aliyun access key',
        accessSecret: 'your aliyun access secret'
    }
###

credential  = require './credential'
alios       = require('../lib/search') credential
testAppName = 'AliOS_Test_2310'

module.exports =
    alios:          alios
    testAppName:    testAppName
    createTestApp:  (cb) -> alios.app.create testAppName, 'builtin_news', cb
    deleteTestApp:  (cb) -> alios.app.delete testAppName, cb
    createError:    (res) ->
        err = new Error
        err.code = res.errors[0].code
        err.message = res.errors[0].message
        err.internal = res.errors
        err
