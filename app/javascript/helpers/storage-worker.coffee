importScripts('vendor/pouchdb.min.js')

db = null

onmessage = (evt) ->
    data = evt.data

    handleResponse = (err, result) ->
        if err
            self.postMessage(
                action: data.action
                error: err
                id: data.id
            )
        else
            self.postMessage(
                action: data.action
                result: result
                id: data.id
            )

    switch data.action
        when 'create'
            db = new PouchDB(data.db)
            db.info(handleResponse)
        else
            handleResponse(new Error('Not Implemented'))

self.addEventListener('message', onmessage, false)
