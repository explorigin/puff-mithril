# components/storage.js
m.factory(
    'helpers.storage'
    () ->
        idIncrement = Math.floor(Math.random() * 100)

        generateId = () ->
            idIncrement += Math.floor(Math.random() * 10)
            return idIncrement

        (server) ->
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
                     d.resolve()
                     d.promise
                signIn: (username, password) ->
                     d = m.deferred()
                     d.resolve()
                     d.promise
                signOut: () ->
                     d = m.deferred()
                     d.resolve()
                     d.promise
                changePassword: (password, newPassword) ->
                     d = m.deferred()
                     d.resolve()
                     d.promise
                changeUsername: (password, newUsername) ->
                     d = m.deferred()
                     d.resolve()
                     d.promise
                resetPassword: (username) ->
                     d = m.deferred()
                     d.resolve()
                     d.promise
                destroy: () ->
                     d = m.deferred()
                     d.resolve()
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
                     d.resolve(obj)
                     d.promise
                update: (type, id, obj) ->
                     d = m.deferred()
                     d.resolve(obj)
                     d.promise
                find: (type, id) ->
                     d = m.deferred()
                     d.resolve([])
                     d.promise
                findAll: (queryFunc) ->
                     d = m.deferred()
                     d.resolve([])
                     d.promise
                remove: (type, id) ->
                     d = m.deferred()
                     d.resolve([])
                     d.promise
                removeAll: (queryFunc) ->
                     d = m.deferred()
                     d.resolve([])
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
)
