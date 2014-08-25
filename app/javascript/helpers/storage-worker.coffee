importScripts('vendor/pouchdb.min.js')

self.db = null

log = () ->

    self.postMessage({
        log: JSON.stringify(Array.prototype.slice.call(arguments, 0, arguments.length))
    })

registerView = (name, funcString) ->
    data = {}
    data[name] = {'map': funcString}

    self.db.put(
        _id: "_design/#{name}"
        language: 'javascript'
        views: data
    )

onmessage = (evt) ->
    data = evt.data

    packet = {
        action: data.action
        id: data.id
    }

    success = (result) ->
        packet.result = result
        self.postMessage(packet)

    fail = (err) ->
        packet.error = err
        self.postMessage(packet)

    switch data.action
        when 'create'
            self.db = new PouchDB(data.args)
            registerView("by_type", "function(doc) { emit([doc.type], doc); }").then(
                ->
                    self.db.info().then(success,fail)
                ->
                    self.db.info().then(success,fail)
            )
        else
            if typeof self.db[data.action] == 'function'
                if typeof data.args == 'object'
                    data.args = [data.args]
                self.db[data.action].apply(self.db, data.args).then(success, fail)
            else
                handleResponse('Not Implemented')

self.addEventListener('message', onmessage, false)
