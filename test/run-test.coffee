describe 'ali-os: ', ->
    { alios, testAppName, createTestApp, deleteTestApp, createError } = require './common'
    should     = require 'should'
    { getInsertDocs, getDeleteDocs } = require './testData'

    # how long are we waiting for the data to effective
    waitFor = 4e3

    insertDocs = null

    it 'listing all of your apps should succeed', (done) ->
        start = +new Date
        alios.app.list 0, 10, (err, res) ->
            should.not.exist err
            res.should.have.property 'status', 'OK'
            res.should.have.property 'result'
            done()

    it 'creating a test app with invalid name should fail', (done) ->
        alios.app.create '::::', 'builtin_news', (err, res) ->
            should.not.exist err
            res.should.have.property 'status', 'FAIL'
            res.should.have.property 'errors'
            res.errors[0].code.should.be.equal 2004
            done()

    it 'creating a test app should succeed', (done) ->
        validate = (res) ->
            res.should.have.property 'status', 'OK'
            res.should.have.property 'result'
            res.result.should.have.property 'index_name', testAppName
            done()

        createTestApp (err, res) ->
            should.not.exist err
            if res.status is 'FAIL'
                if res.errors[0].code is 2002 #App already exists'
                    deleteTestApp (err, res) ->
                        should.not.exist err
                        res.should.have.property 'status', 'OK'
                        createTestApp (err, res) ->
                            should.not.exist err
                            validate res
                else
                    done createError res
            else
                validate res

    it "waiting for the app to effective" , (done) ->
        setTimeout done, 4000

    it 'getting info. of test app should succeed', (done) ->
        alios.app.status testAppName, (err, res) ->
            should.not.exist err
            res.should.have.property 'status', 'OK'
            res.should.have.property 'result'
            res.result.index_name.should.be.equal testAppName
            done()

    it 'adding docs should succeed', (done) ->
        insertDocs = getInsertDocs()
        alios.pushDocs testAppName, 'main', insertDocs, (err, res) ->
            done()

    it "waiting for the docs to effective" , (done) ->
        setTimeout done, 4000

    it 'searching for the docs just inserted should succeed', (done) ->
        props =
            query: "query=title:'doc'"
            index_name: testAppName
        alios.search props, (err, res) ->
            should.not.exist err
            res.should.have.property 'status', 'OK'
            res.should.have.property 'result'
            retDocs = res.result.items
            retDocs.length.should.equal insertDocs.length

            expected =
                ids: insertDocs.map (doc) -> doc.fields.id
                titles: insertDocs.map (doc) -> doc.fields.title
            for doc in retDocs
                expected.ids.should.containEql doc.id
                expected.titles.should.containEql doc.title
            done()

    it 'deleting docs should succeed', (done) ->
        alios.pushDocs testAppName, 'main', getDeleteDocs(), (err, res) ->
            done()

    it "waiting for the docs to be removed", (done) ->
        setTimeout done, 4000

    it 'confirm all of the docs have been deleted', (done) ->
        props =
            query: "query=title:'doc'"
            index_name: testAppName
        alios.search props, (err, res) ->
            should.not.exist err
            res.should.have.property 'status', 'OK'
            res.should.have.property 'result'
            retDocs = res.result.items
            retDocs.length.should.equal 0
            done()

    it 'delete test app for cleanup', (done) ->
        alios.app.delete testAppName, (err, res) ->
            done err