# models/image.js
m.factory(
    'models.image'
    [
        'helpers.photo-utils'
        'helpers.storage'
    ]
    (PhotoUtils, Storage) ->
        db = Storage('puff')

        # Utility functions
        resizeImg = (img, maxWidth, maxHeight) ->
            # Resizes src Javascript Image to maxWidth x maxHeight (but maintaining the same aspect ratio)

            d = m.deferred()

            if not img.src
                d.reject(new Error('No original image exists to build screenImg from.'))

            outImage = PhotoUtils.resize(img, maxWidth, maxHeight)
            outImage.onload = ->
                d.resolve(outImage)
            return d.promise


        # Image model
        return (initialData) ->
            self = @

            _ready = m.deferred()

            @_id = m.prop(initialData._id)
            @_rev = m.prop(initialData._rev)
            @ready = _ready.promise

            # Shadow Properties
            @_hash = m.prop(initialData.hash or null)

            # Image properties
            @blob = m.prop(initialData.blob or null)
            @src = m.prop(initialData.src or null)
            @original = m.prop(null)
            @screenImg = m.prop(null)
            @smallImg = m.prop(null)
            @width = m.prop(initialData.width or 400)
            @height = m.prop(initialData.height or 300)
            @mimetype = m.prop(initialData.mimetype or initialData.type or 'image/*')
            @filename = m.prop(initialData.filename or initialData.name or '[unnamed]')
            @lastModifiedDate = m.prop(new Date(initialData.lastModifiedDate or null))
            @aspectRatio = m.prop(initialData.aspectRatio or 1.33)

            # Computed Image Properties
            @hash = ->
                if not self._hash()
                    if not self.original()
                        return null
                    self._hash(md5(self.original().src))
                return self._hash()

            @saved = () ->
                return db.IDENTIFIER_KEYS.every((x) -> self[x]())

            # Methods
            @save = ->
                saveBlob = ->
                    d = m.deferred()
                    if not self.blob()
                        d.resolve(self)
                    else
                        db.store.updateAttachment(self._id(), 'original', self.blob(), self.mimetype())
                            .then(-> d.resolve(self))
                    return d.promise

                data =
                    hash: self.hash()
                    mimetype: self.mimetype()
                    filename: self.filename()
                    lastModifiedDate: self.lastModifiedDate()
                    aspectRatio: self.aspectRatio()

                # Save the src if it is not a data url
                if typeof self.src() is 'string' and self.src().slice(0, 4) isnt 'data'
                    data.src = self.src()

                if self._id()
                    return db.store.update('image', self._id(), data)
                        .then(saveBlob)
                else
                    return db.store.add('image', data)
                        .then( (result) -> self._id(result.id))
                        .then(saveBlob)

            @remove = ->
                db.store.remove('image', self._id())

            @resizeSmallImg = (width, height) ->
                resizeImg(self.screenImg(), width, height)
                .then(
                    (img) ->
                        self.smallImg(img)
                        self.width(width)
                        self.height(height)
                )

            @loadFromImageOnload = (evt) ->
                img = evt.target
                self.aspectRatio(img.width / img.height)
                self.original(img)

                # FIXME - strip EXIF data?
                resizeImg(
                    img
                    window.screen.width
                    window.screen.height
                ).then( (screenImg) ->
                    self.screenImg(screenImg)
                    resizeImg(
                        img
                        Math.floor(self.width())
                        Math.floor(self.width() / self.aspectRatio())
                    )
                ).then( (smallImg) ->
                    self.smallImg(smallImg)
                    if not self.saved()
                        self.save()
                ).then(->
                    # Clear original and blob to save memory
                    self.original(null)
                    self.blob(null)
                    _ready.resolve(self)
                )

            # Initialization
            if initialData instanceof File
                img = new Image()
                img.onload = self.loadFromImageOnload
                img.src = window.URL.createObjectURL(initialData)
                self.blob(initialData)

            else if self.saved()
                if initialData._attachments and initialData._attachments.hasOwnProperty('original')
                    db.store.getAttachment(self._id(), 'original').then(
                        (blob) ->
                            img = new Image()
                            img.onload = self.loadFromImageOnload
                            img.src = window.URL.createObjectURL(blob)
                            self.blob(blob)
                        (error) ->
                            self.remove()
                            _ready.reject(error)
                    )
                else if initialData.src
                    img = new Image()
                    img.onload = self.loadFromImageOnload
                    img.src = window.URL.createObjectURL(blob)
                else
                    self.remove()
                    _ready.reject(new Error('Cannot load image without data.'))
            else
                _ready.resolve(@)

            return @
)
