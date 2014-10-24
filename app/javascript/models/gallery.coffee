# models/image.js
require('mithril')
require('config')
require('helpers/storage')
require('models/image')
require('helpers/utils')
require('helpers/photo-utils')

md5 = require('external/md5-jkm.js')

m.factory(
    'models.gallery'
    [
        'application.config'
        'models.image'
        'helpers.storage'
        'helpers.photo-utils'
    ]
    (cfg, GalleryImage, Storage, PhotoUtils) ->
        borderSize = cfg.apps.gallery.borderSize
        UI_DELAY = cfg.ui_delay
        scrollBarWidth = PhotoUtils.scrollBarWidth()

        db = Storage('puff')

        debugErrors = -> m.log(arguments)

        Album = (initialData) ->
            self = @

            _ready = m.deferred()
            @ready = _ready.promise

            @_id = m.prop(initialData._id)
            @_rev = m.prop(initialData._rev)

            @images = m.prop(initialData.images or [])
            @name = m.prop(initialData.name or '')
            @ready = _ready.promise

            @saved = () -> db.IDENTIFIER_KEYS.every((x) -> self[x]())

            @addImage = (image) ->
                id = m.unwrap(image._id)
                if id not in self.images()
                    self.images().push(id)
                    return true
                return false

            @save = ->
                data =
                    images: self.images()
                    name: self.name()

                m.log(data)

                if self._id()
                    return db.store.update('album', self._id(), data).then(m.log, m.log)
                else
                    return db.store.add('album', data)
                        .then(
                            (result) -> self._id(result.id)
                            debugErrors
                        )

            _ready.resolve()

            return @

        return ->
            self = @
            resizeImageLock = null

            _ready = m.deferred()

            # Properties
            @images = m.prop([])  # Array of Gallery Photo controllers
            @files = m.prop([])  # Incoming files
            @container = m.prop(null)
            @albums = m.prop({})
            @activeAlbumId = m.prop(null)
            @ready = _ready.promise

            # Computed Properties
            @activeAlbum = -> self.albums()[self.activeAlbumId()]
            @containerWidth = -> if self.container() then self.container().clientWidth - scrollBarWidth else 0
            @containerHeight = -> if self.container() then self.container().clientHeight else 0
            @containerAspectRatio = -> if self.container() then self.containerWidth() / self.containerHeight() else 1

            @optimalImageHeight = -> window.screen.height * cfg.apps.gallery.optimalImageHeightRatio

            @totalOptimalImageWidth = ->
                optimalHeight = @optimalImageHeight()
                self.images().reduce(
                    (sum, i) -> sum + i.aspectRatio() * optimalHeight
                    0
                )

            @partitions = ->
                rowCount = Math.ceil(@totalOptimalImageWidth() / self.containerWidth())
                partition(self.images().map((i) -> i.aspectRatio() * 100), rowCount)

            # Methods
            @resizeImages = ->
                if resizeImageLock isnt null
                    return resizeImageLock.promise

                resizeImageLock = m.deferred()

                rows = self.partitions()
                index = 0
                total = 0
                vpWidth = self.containerWidth() * 100
                for row in rows
                    # Linear partition will inject empty rows to complete the mathmatic equation.  Here we just ignore those rows.
                    break unless row.length > 0

                    summedAspectRatios = row.reduce(((sum, ar) -> sum + ar), 0)
                    if (summedAspectRatios / 100) < self.containerAspectRatio()
                        summedAspectRatios = self.containerAspectRatio() * 100
                    modifiedWidth = vpWidth / summedAspectRatios
                    endPoint = row.length - 1 + index
                    for img_index in [index..endPoint]
                        img = self.images()[img_index]
                        img.resizeSmallImg(
                            (modifiedWidth - borderSize) * img.aspectRatio()
                            modifiedWidth - borderSize
                        ).then(m.redraw)
                        total += 1

                    index += row.length

                r = resizeImageLock
                resizeImageLock = null
                r.resolve(total)

                return r.promise

            _importNextFile = ->
                # Read the top file.
                return unless file = self.files().shift()

                m.log(file.name)

                img = new GalleryImage(file)
                img.ready.then(
                    (instance) ->
                        # Grab the md5 precomputed hashes of the existing images
                        imageHashes = m.pluck(self.activeAlbum().images(), 'hash').map((hash) -> hash())
                        # If the image is not already in the group, then add it and resize all the images.
                        if instance.hash() not in imageHashes
                            self.images().push(instance)
                            if self.activeAlbum().addImage(instance)
                                self.activeAlbum().save()
                            return self.resizeImages()
                    (err) ->
                        m.log(err)
                        setTimeout(_importNextFile, UI_DELAY)
                ).then(
                    (added) ->
                        m.redraw()
                        setTimeout(_importNextFile, UI_DELAY) unless added is 0
                    (err) ->
                        m.log(err)
                        setTimeout(_importNextFile, UI_DELAY)
                )

            @importFiles = (files) ->
                # Filter for just our image files
                self.files(Array.prototype.filter.call(files, (f) -> f.type.indexOf('image/') is 0))
                # Give a delay for the UI to update between image loads.
                setTimeout(_importNextFile, UI_DELAY)

            importImages = (records) ->
                m.sync(m.pluck(records.map((img) -> new GalleryImage(img)), 'ready')).then(
                    (loadedImages) ->
                        added = false
                        for image in loadedImages
                            if self.activeAlbum().addImage(image)
                                added = true
                            self.images().push(image)
                        if added
                            self.activeAlbum().save()
                        self.resizeImages()
                    (rejectedImages) ->
                        # images = rejectedImages.filter((i) -> i.ready and i.ready() isnt null)
                        # self.images().push.apply(self.images(), images)
                        m.log(
                            "ERROR: Some images could not be loaded.",
                            rejectedImages.filter((i) -> not i.ready or i.ready() is null))
                        self.resizeImages()
                )

            # Initialization Processing
            resolveIt = ->
                console.log('')
                _ready.resolve(self)

            findAlbums = ->
                attempts = 100
                deferred = m.deferred()

                _resolveFindAlbums = -> deferred.resolve()
                _findAlbum = -> db.store.findAll('album')

                _albumFound = (result) ->
                    if not result.rows.length
                        m.log('Error creating initial Album.')
                        throw result

                    for albumRecord in result.rows
                        self.albums()[albumRecord.id] = new Album(albumRecord.value)
                    self.activeAlbumId(result.rows[0].id)

                    m.sync(self.activeAlbum().images().map((id) -> db.store.find('image', id))).then(
                        (imagesResult) ->
                            importImages(imagesResult).then(_resolveFindAlbums, _resolveFindAlbums)
                        _resolveFindAlbums
                    )

                _checkResult = (result) ->
                    if not result.rows.length
                        album = new Album({name: '[New Album]'})
                        return album.save().then(_findAlbum, _fail).then(_checkResult, _delay)
                    return _albumFound(result)

                _delay = ->
                    attempts -= 1
                    if attempts is 0
                        deferred.reject('No database found.')

                    setTimeout(
                        -> _findAlbum().then(_checkResult, _delay)
                        10
                    )

                _findAlbum().then(_checkResult, _delay)

                return deferred.promise

            _fail = -> m.alert('Error creating initial Album.')

            findAlbums().then(resolveIt, _fail)

            return @
)
