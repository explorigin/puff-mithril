importScripts('vendor/pouchdb.min.js')

self.db = null

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

onmessage = (evt) ->
    data = evt.data

    switch data.action
        when 'create'
            self.db = new PouchDB(data.db)
            self.db.info(handleResponse)

        when 'findAll'
            self.db.query('by_type', {key: [data.type], attachments:true}, handleResponse)

        when 'updateAttachment'
            db.putAttachment(data.id, data.attId, data.rev, data.attachment, data.mimetype, handleResponse)

        when 'getAttachment'
            db.getAttachment(data.id, data.attachmentId, handleResponse)

        else
            handleResponse('Not Implemented')

self.addEventListener('message', onmessage, false)
