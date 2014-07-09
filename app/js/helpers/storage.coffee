# helpers/storage.js
m.factory(
    'helpers.storage'
    () ->
        dbCache = {}
        revMap = {}

        handleResponse = (d) ->
            (err, result) ->
                if err
                    return d.reject(err)
                else if result.id and result.rev
                    revMap[result.id] = result.rev
                d.resolve(result)

        API = (db) ->
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
                    map = (doc, emit) ->
                        if doc.type is type
                            emit(null, doc)
                    db.query(map, {attachments:true}, handleResponse(d))
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

            return @

        API.prototype.IDENTIFIER_KEYS = ['_id', '_rev']

        (databaseUri) ->
            if databaseUri not in dbCache
                dbCache[databaseUri] = new API(new PouchDB(databaseUri))
            return dbCache[databaseUri]
)
