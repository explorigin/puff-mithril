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
        'helpers.utils'
        'helpers.photo-utils'
    ]
    (cfg, GalleryImage, Storage, utils, PhotoUtils) ->
        borderSize = cfg.apps.gallery.borderSize
        UI_DELAY = 20
        scrollBarWidth = PhotoUtils.scrollBarWidth()

        db = Storage('puff')

        return ->
            self = @
            resizeImageLock = null

            _ready = m.deferred()

            # Properties
            @images = m.prop([])  # Array of Gallery Photo controllers
            @optimalImageHeightRatio = m.prop(3/8)
            @files = m.prop([])  # Incoming files
            @container = m.prop(null)
            @ready = _ready.promise

            # Computed Properties
            @containerWidth = -> if self.container() then self.container().clientWidth - scrollBarWidth else 0
            @containerHeight = -> if self.container() then self.container().clientHeight else 0
            @containerAspectRatio = -> if self.container() then self.containerWidth() / self.containerHeight() else 1

            @optimalImageHeight = -> window.screen.height * @optimalImageHeightRatio()

            @totalOptimalImageWidth = ->
                optimalHeight = @optimalImageHeight()
                @images().reduce(
                    (sum, i) -> sum + i.aspectRatio() * optimalHeight
                    0
                )

            @partitions = ->
                rowCount = Math.ceil(@totalOptimalImageWidth() / self.containerWidth())
                partition(@images().map((i) -> i.aspectRatio() * 100), rowCount)

            # Methods
            @resizeImages = ->
                if resizeImageLock isnt null
                    return resizeImageLock.promise

                resizeImageLock = m.deferred()
                window.images  = self.images()

                rows = @partitions()
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
                        img = @images()[img_index]
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

                utils.log(file.name)

                img = new GalleryImage(file)
                img.ready.then(
                    (instance) ->
                        # Grab the md5 precomputed hashes of the existing images
                        imageHashes = _.pluck(self.images(), 'hash').map((hash) -> hash())
                        # If the image is not already in the group, then add it and resize all the images.
                        if instance.hash() not in imageHashes
                            self.images().push(instance)
                            return self.resizeImages()
                    (err) ->
                        utils.log(err)
                        setTimeout(_importNextFile, UI_DELAY)
                ).then(
                    (added) ->
                        m.redraw()
                        setTimeout(_importNextFile, UI_DELAY) unless added is 0
                    (err) ->
                        utils.log(err)
                        setTimeout(_importNextFile, UI_DELAY)
                )

            @importFiles = (files) ->
                # Filter for just our image files
                self.files(_.filter(files, (f) -> f.type.indexOf('image/') is 0))
                # Give a delay for the UI to update between image loads.
                setTimeout(_importNextFile, UI_DELAY)

            importImages = (records) ->
                m.sync(_.pluck(records.map((img) -> new GalleryImage(img)), 'ready')).then(
                    (loadedImages) ->
                        self.images().push.apply(self.images(), loadedImages)
                        self.resizeImages()
                    (rejectedImages) ->
                        images = rejectedImages.filter((i) -> i.ready and i.ready() isnt null)
                        self.images().push.apply(self.images(), images)
                        utils.log(
                            "ERROR: Some images could not be loaded.",
                            rejectedImages.filter((i) -> not i.ready or i.ready() is null))
                        self.resizeImages()
                )

            # Initialization Processing
            resolveIt = ->
                _ready.resolve(self)

            db.store.findAll('image').then(
                (result) ->
                    if not result.rows.length
                        return resolveIt()
                    importImages(result.rows.map((r) -> r.value)).then(resolveIt, resolveIt)
                resolveIt
            )

            return @
)
