# helpers/storage.js
require('mithril')
PouchDB = require('pouchdb/dist/pouchdb.min.js')  #  Separate so the worker can access it.
StorageWorker = require('worker!helpers/storage-worker')

m.factory(
    'helpers.storage'
    ->
        dbCache = {}
        revMap = {}

        handleResponse = (d) ->
            (err, result) ->
                if err
                    return d.reject(err)
                else if result.id and result.rev
                    revMap[result.id] = result.rev
                d.resolve(result)

        API = (db, worker) ->
            readyDeferred = m.deferred()
            workerJobs = {}

            subscriptions =
                account:
                    signup: {}
                    signin: {}
                    signout: {}
                    authenticated: {}
                    unauthenticated: {}
                store:
                    add: {}
                    update: {}
                    remove: {}
                    change: {}
                remote:
                    add: {}
                    update: {}
                    remove: {}
                    change: {}

            populateRev = (docId, saveRev = true) ->
                d = m.deferred()
                db.get(
                    docId
                    (err, result) ->
                        revMap[docId] = result._rev unless saveRev isnt true
                        d.resolve(result._rev)
                )
                d.promise

            postMessage = (action, id, packet) ->
                d = m.deferred()

                if workerJobs[action] is undefined
                    workerJobs[action] = {}
                workerJobs[action][id] = d

                if packet.action isnt action
                    packet.action = action
                if packet.id isnt id
                    packet.id = id

                worker.postMessage(packet)
                return d.promise

            receiveMessage = (msg) ->
                data = msg.data
                if data.error
                    action = 'reject'
                    response = data.error
                else
                    action = 'resolve'
                    response = data.result

                try
                    workerJobs[data.action][data.id][action](response)
                catch e
                    console.log('Receive ERROR')
                    console.log(e, msg)

            if worker
                worker.addEventListener('message', receiveMessage, false)
                db.info(
                    (err, info) ->
                        postMessage('create', 0, {db: info.db_name}).then(
                            ->
                                console.log(arguments)
                                # TODO - when we fully support workers, close the db on this end.
                                # db.close()
                                readyDeferred.resolve()
                            (err) ->
                                console.log("Storage warning: no worker support for #{info.db_name}. ERROR: #{err}");
                                worker = null
                                readyDeferred.resolve()
                        )
                )
            else
                readyDeferred.resolve()

            @account =
                signUp: (username, password) ->
                     d = m.deferred()
                     d.reject({msg: 'Not Implemented'})
                     d.promise
                signIn: (username, password) ->
                     d = m.deferred()
                     d.resolve(true)
                     d.promise
                signOut: () ->
                     d = m.deferred()
                     d.resolve(true)
                     d.promise
                changePassword: (password, newPassword) ->
                     d = m.deferred()
                     d.reject({msg: 'Not Implemented'})
                     d.promise
                changeUsername: (password, newUsername) ->
                     d = m.deferred()
                     d.reject({msg: 'Not Implemented'})
                     d.promise
                resetPassword: (username) ->
                     d = m.deferred()
                     d.reject({msg: 'Not Implemented'})
                     d.promise
                destroy: () ->
                     d = m.deferred()
                     d.reject({msg: 'Not Implemented'})
                     d.promise
                username: m.prop(null)
                on: (evtName, callback) ->
                    if subscriptions.account[evtName] is undefined
                        throw new Error("No such event \"#{evtName}\"")

                    id = generateId()
                    subscriptions.account[evtName][id] = callback

            @store =
                _db: db
                registerView: (obj) ->
                    m.sync(
                        Object.keys(obj).map(
                            (key) ->
                                data = {}
                                data[key] = {'map': obj[key]}

                                db.put(
                                    _id: "_design/#{key}"
                                    language: 'javascript'
                                    views: data
                                )
                        )
                    )

                add: (type, obj) ->
                    d = m.deferred()
                    obj.type = type
                    db.post(obj, handleResponse(d))
                    d.promise

                update: (type, docId, obj) ->
                    d = m.deferred()
                    rev = revMap[docId]
                    put = (rev) ->
                        db.put(obj, docId, rev, handleResponse(d))

                    obj.type = type

                    if not rev
                        populateRev(docId).then(put, (err) -> d.reject(err))
                    else
                        put(rev)

                    d.promise
                updateAttachment: (docId, attId, attachment, mimetype) ->
                    d = m.deferred()
                    rev = revMap[docId]
                    put = (rev) ->
                        if worker
                            postMessage(
                                'updateAttachment',
                                docId,
                                rev: rev
                                attId: attId
                                attachment: attachment,
                                mimetype: mimetype
                            ).then(d.resolve)
                        else
                            db.putAttachment(docId, attId, rev, attachment, mimetype, handleResponse(d))

                    if worker
                        d.reject()
                        return postMessage(
                            'updateAttachment',
                            docId,
                            rev: rev
                            attId: attId
                            attachment: attachment,
                            mimetype: mimetype
                        )
                    else
                        if not rev
                            populateRev(docId).then(put, (err) -> d.reject(err))
                        else
                            put(rev)

                    d.promise
                getAttachment: (docId, attachmentId) ->
                    d = m.deferred()
                    if worker
                        d.reject()
                        return postMessage('getAttachment', docId, {attachmentId:attachmentId})
                    db.getAttachment(docId, attachmentId, handleResponse(d))
                    d.promise
                removeAttachment: (docId, attachmentId) ->
                    d = m.deferred()
                    rev = revMap[docId]
                    remove = (rev) ->
                        db.removeAttachment(docId, attachmentId, rev, handleResponse(d))

                    if not rev
                        populateRev(id).then(remove, (err) -> d.reject(err))
                    else
                        remove(rev)

                    d.promise
                find: (type, id) ->
                    d = m.deferred()
                    d.resolve([])
                    d.promise
                findAll: (type) ->
                    d = m.deferred()

                    if worker
                        d.reject()
                        return postMessage('findAll', type, {type:type})

                    db.query('by_type', {key: [type], attachments:true}, handleResponse(d))
                    d.promise
                remove: (type, docId) ->
                    d = m.deferred()
                    rev = revMap[docId]
                    remove = (rev) ->
                        db.remove(docId, rev, handleResponse(d))
                        delete revMap[docId]

                    if not rev
                        populateRev(docId).then(remove, (err) -> d.reject(err))
                    else
                        remove(rev)

                    d.promise
                removeAll: (queryFunc) ->
                     d = m.deferred()
                     d.reject({msg: 'Not Implemented'})
                     d.promise
                on: (evtName, callback) ->
                    if subscriptions.store[evtName] is undefined
                        throw new Error("No such event \"#{evtName}\"")

                    id = generateId()
                    subscriptions.account[evtName][id] = callback

            @remote =
                on: (evtName, callback) ->
                    if subscriptions.remote[evtName] is undefined
                        throw new Error("No such event \"#{evtName}\"")

                    id = generateId()
                    subscriptions.account[evtName][id] = callback


            @store.registerView({"by_type": "function(doc) { emit([doc.type], doc); }"})

            @ready = readyDeferred.promise
            return @

        API.prototype.IDENTIFIER_KEYS = ['_id', '_rev']

        (databaseUri) ->
            if dbCache[databaseUri] is undefined
                try
                    worker = new StorageWorker();
                catch e
                    console.log("Storage warning: no worker support for #{databaseUri}", e);
                    worker = null

                dbCache[databaseUri] = new API(new PouchDB(databaseUri), worker)
            return dbCache[databaseUri]
)
