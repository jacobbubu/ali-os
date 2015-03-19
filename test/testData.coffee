docCount = 2

getInsertDocs = ->
    data  = []
    timeStr = new Date().toLocaleTimeString()
    for i in [0...docCount]
        data.push {
            cmd: 'add'
            fields:
                id: i.toString()
                title: 'title of doc' + i
                body: 'body of doc' + i + ' ' + timeStr
        }
    data

getDeleteDocs = ->
    data  = []
    for i in [0...docCount]
        data.push {
            cmd: 'delete'
            fields:
                id: i.toString()
        }
    data

module.exports =
    getInsertDocs: getInsertDocs
    getDeleteDocs: getDeleteDocs