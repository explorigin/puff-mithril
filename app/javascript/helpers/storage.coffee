# helpers/storage.js
require('mithril')
PouchDB = require('pouchdb/dist/pouchdb.min.js')  #  Separate so the worker can access it.
StorageWorker = require('worker!helpers/storage-worker')

m.factory(
    'helpers.storage'
    ->
        dbCache = {}
        revMap = {}

        handleResponse = (deferred) ->
            (err, result) ->
                if err
                    console.log(err)
                    return deferred.reject(err)
                else if result.id and result.rev
                    revMap[result.id] = result.rev
                deferred.resolve(result)

        # WorkerProxy = (databaseUri) ->
        #     self = @

        #     worker = new StorageWorker()
        #     uniqueID = 0
        #     workerJobs = {create:{}}
        #     readyDeferred = m.deferred()
        #     @ready = readyDeferred.promise
        #     queue = []

        #     _commands = [
        #         'post'
        #         'put'
        #         'query'
        #         'remove'
        #         'getAttachment'
        #         'putAttachment'
        #         'removeAttachment'
        #         'create'
        #         'info'
        #     ]

        #     _postMessage = (action, args) ->
        #         deferred = m.deferred()
        #         id = uniqueID++

        #         if workerJobs[action] is undefined
        #             workerJobs[action] = {}
        #         workerJobs[action][id] = deferred

        #         packet = {
        #             action: action
        #             id: id
        #             args: args
        #         }

        #         if self.ready()
        #             console.log("Posting: ", packet)
        #             worker.postMessage(packet)
        #         else
        #             console.log("Queuing: ", packet)
        #             queue.push(packet)

        #         return deferred.promise

        #     _receiveMessage = (msg) ->
        #         data = msg.data
        #         console.log("Received: ", data)

        #         if data.log
        #             try
        #                 console.log('Worker log: ', JSON.parse(data.log))
        #             catch e
        #                 console.log(data.log)
        #             return

        #         if data.error
        #             action = 'reject'
        #             response = data.error
        #         else
        #             action = 'resolve'
        #             response = data.result

        #         try
        #             workerJobs[data.action][data.id][action](response)
        #         catch e
        #             console.log('Receive ERROR')
        #             console.log(e)
        #             console.log(e.stack)
        #             console.log(msg)
        #         delete workerJobs[data.action][data.id]

        #     _commands.forEach(
        #         (cmd) ->
        #             self[cmd] = -> _postMessage(cmd, arguments)
        #     )

        #     worker.addEventListener('message', _receiveMessage, false)
        #     worker.onerror = (e) ->
        #         throw new Error(e)

        #     workerJobs['create'][uniqueID] = readyDeferred
        #     packet = {action:'create', id:uniqueID++, args:databaseUri + '-worker'}
        #     console.log("Initial Posting: ", packet)
        #     worker.postMessage(packet)

        #     return @

        API = (database) ->
            db = database

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

            subscriberFactory = (part) ->
                (evtName, callback) ->
                    if subscriptions[part][evtName] is undefined
                        throw new Error("No such event \"#{evtName}\"")

                    id = generateId()
                    subscriptions[part][evtName][id] = callback

            notImplemented = ->
                deferred = m.deferred()
                deferred.reject({msg: 'Not Implemented'})
                deferred.promise

            populateRev = (docId, saveRev = true) ->
                deferred = m.deferred()
                db.get(
                    docId
                    (err, result) ->
                        revMap[docId] = result._rev unless saveRev isnt true
                        deferred.resolve(result._rev)
                )
                deferred.promise

            @account =
                signUp: notImplemented
                signIn: (username, password) ->
                     d = m.deferred()
                     d.resolve(true)
                     d.promise
                signOut: () ->
                     d = m.deferred()
                     d.resolve(true)
                     d.promise
                changePassword: notImplemented
                changeUsername: notImplemented
                resetPassword: notImplemented
                destroy: notImplemented
                username: m.prop(null)
                on:  subscriberFactory('account')

            @store =
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
                        db.putAttachment(docId, attId, rev, attachment, mimetype, handleResponse(d))

                        if not rev
                            populateRev(docId).then(put, (err) -> d.reject(err))
                        else
                            put(rev)

                    d.promise
                getAttachment: (docId, attachmentId) ->
                    d = m.deferred()
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
                removeAll: notImplemented
                on:  subscriberFactory('store')

            @remote =
                on: subscriberFactory('remote')

            @store.registerView({"by_type": "function(doc) { emit([doc.type], doc); }"})

            return @

        API.prototype.IDENTIFIER_KEYS = ['_id', '_rev']

        (databaseUri) ->
            cachedValue = dbCache[databaseUri]

            # inMainThread = (err) ->
            #     console.log("Storage warning: no worker support for #{databaseUri}")
            #     if err
            #         console.log(err.stack)
            #     a = dbCache[databaseUri] = new API(new PouchDB(databaseUri))
            #     deferred.resolve(a)

            if cachedValue is undefined
                # try
                #     worker = new WorkerProxy(databaseUri)
                #     dbCache[databaseUri] = deferred.promise
                #     worker.ready.then(
                #         ->
                #             worker.ready(true)
                #             a = dbCache[databaseUri] = new API(worker)
                #             deferred.resolve(a)
                #             return null
                #         inMainThread
                #     )
                # catch e
                #     inMainThread(e)
                cachedValue = dbCache[databaseUri] = new API(new PouchDB(databaseUri))

            return cachedValue
)
