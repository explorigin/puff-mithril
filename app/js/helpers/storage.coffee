# helpers/storage.js
m.factory(
    'helpers.storage'
    () ->
        dbCache = {}
        revMap = {}

        populateRev = (id, saveRev = true) ->
            d = m.deferred()
            db.get(
                id
                (err, result) ->
                    revMap[id] = result._rev unless saveRev isnt true
                    d.resolve(result._rev)
            )
            d.promise

        handleResponse = (d) ->
            (err, result) ->
                console.log(err, result)
                if err
                    return d.reject(err)
                else if result.id
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
                add: (type, obj, attachmentType, attachment) ->
                    d = m.deferred()
                    obj.type = type
                    db.post(obj, handleResponse(d))
                    d.promise
                update: (type, id, obj, attachmentType, attachment) ->
                    d = m.deferred()
                    rev = revMap[id]
                    put = (rev) ->
                        db.put(obj, id, rev, handleResponse(d))

                    obj.type = type

                    if not rev
                        populateRev(id).then(put, (err) -> d.reject(err))
                    else
                        put(rev)

                    d.promise
                updateAttachment: (id, attId, attachment, mimetype) ->
                    d = m.deferred()
                    rev = revMap[id]
                    put = (rev) ->
                        db.putAttachment(id, attId, rev, attachment, mimetype, handleResponse(d, false))

                    if not rev
                        populateRev(id).then(put, (err) -> d.reject(err))
                    else
                        put(rev)

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
                    db.query(map, handleResponse(d, false))
                    d.promise
                remove: (type, id) ->
                     d = m.deferred()
                     d.reject({msg: 'Not Implemented'})
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

        (databaseUri) ->
            if databaseUri not in dbCache
                dbCache[databaseUri] = new API(new PouchDB(databaseUri))
            return dbCache[databaseUri]
)
