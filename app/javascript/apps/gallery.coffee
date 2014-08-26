require('mithril')
require('config')
require('models/image')
require('helpers/icon')
require('helpers/photo-utils')
require('helpers/storage')

_ = require('lodash')
partition = require('external/linear_partition')

m.factory(
    'apps.gallery',
    [
        'application.config'
        'models.image'
        'helpers.icon'
        'helpers.photo-utils'
        'helpers.storage'
    ]
    (cfg, GalleryImage, Icon, PhotoUtils, Storage) ->
        scrollBarWidth = PhotoUtils.scrollBarWidth()
        borderSize = 4
        UI_DELAY = 20

        currentGallery = null
        clearGalleryTimeout = null

        db = new Storage('puff')

        Gallery = ->
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

                console.log(file.name)

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
                        console.log(err)
                        setTimeout(_importNextFile, UI_DELAY)
                ).then(
                    (added) ->
                        m.redraw()
                        setTimeout(_importNextFile, UI_DELAY) unless added is 0
                    (err) ->
                        console.log(err)
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
                        console.log(
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

        controller: () ->
            window.s = self = @  # window.s for debugging

            @gallery = m.prop(currentGallery or new Gallery())
            @mode = m.prop('loading')
            @modeChangeTimeout = m.prop()
            @focusIndex = m.prop(null)

            refreshDimensions = (evt) ->
                # Defer refreshing the container dimensions so we know that the container has resized
                setTimeout(
                    ->
                        m.startComputation()
                        self.gallery().resizeImages().then(m.endComputation)
                    0
                )
            @resizeSubscription = window.addEventListener('resize', refreshDimensions)
            @onunload = ->
                window.removeEventListener('resize', refreshDimensions)

                # After 30 seconds allow the gallery to be garbage collected
                clearGalleryTimeout = setTimeout(
                    ->
                        clearGalleryTimeout = null
                        currentGallery = null
                    30000
                )

            # Event Interactions
            @toggleFocusOnImage = (index) ->
                ->
                    if self.focusIndex() == index
                        index = null
                    self.focusIndex(index)
                    self.mode(if index is null then 'grid' else 'showcase')

            @removeImage = (index) ->
                ->
                    if self.focusIndex() == index
                        self.focusIndex(null)
                    img = self.gallery().images().splice(index, 1)
                    img[0].remove()
                    if self.gallery().images().length
                        self.mode('grid')
                        self.gallery().resizeImages()
                    else
                        self.mode('draghover')


            @dragDrop = (evt) ->
                self.gallery().importFiles(evt.dataTransfer.files)

                # We're finished dropping, go back to gallery mode to display images as they come in.
                self.mode('grid')
                return false

            @dragEnter = (evt) ->
                self.mode('draghover')
                if self.modeChangeTimeout()
                    clearTimeout(self.modeChangeTimeout())
                    self.modeChangeTimeout(null)

            @dragLeave = (evt) ->
                self.modeChangeTimeout(
                    setTimeout(
                        ->
                            self.mode('grid')
                            m.redraw()
                            self.modeChangeTimeout(null)
                        100
                    )
                )

            @dragOver = (evt) =>
                # This is needed to tell the browser that the element can accept a drop.
                evt.preventDefault()

            @prevImage = ->
                self.focusIndex(Math.max(self.focusIndex() - 1, 0))

            @nextImage = ->
                self.focusIndex(Math.min(self.focusIndex() + 1, self.gallery().images().length - 1))

            @viewConfig = (el, previouslyCreated) ->
                g = self.gallery()
                width = g.containerWidth()
                height = g.containerHeight()

                g.container(el)

                if g.containerWidth() != width or g.containerHeight() != height
                    refreshDimensions()

            currentGallery = self.gallery()
            clearTimeout(clearGalleryTimeout) unless clearGalleryTimeout is null

            currentGallery.ready.then(
                () ->
                    if currentGallery.images().length
                        self.mode('grid')
                    else
                        self.mode('draghover')
                    m.redraw()
                (err) ->
                    console.log('Error: ' + err)
            )

            return @

        view: (ctrl) ->
            g = ctrl.gallery()

            albumImgTmpl = (img, index) ->
                width = img.width()
                height = img.height()
                src = img.smallImg().src

                [
                    m(
                        'img.image'
                        {
                            style: "width: #{width}px; height: #{height}px"
                            src: src
                            onclick: ctrl.toggleFocusOnImage(index)
                        }
                    )
                    # Icon('times', {'class':'remove', onclick: ctrl.removeImage(index)})
                ]

            zoomImgTmpl = (img, index) ->
                return '' unless img

                 # When focusing, maximized the image to the container
                if g.containerAspectRatio() < img.aspectRatio()
                    width = g.containerWidth() - borderSize
                    height = width / img.aspectRatio()
                else
                    height = g.containerHeight() - borderSize
                    width = height * img.aspectRatio()

                src = img.screenImg().src

                [
                    m(
                        '.image'
                        [
                            m(
                                'img'
                                {
                                    style: "width: #{width}px; height: #{height}px"
                                    src: src
                                    onclick: ctrl.toggleFocusOnImage(index)
                                }
                            )
                            m(
                                '.button_bar'
                                [
                                    Icon('times', {'class':'remove', onclick: ctrl.removeImage(index)})
                                ]
                            )
                        ]
                    )
                ]


            m(
                '.gallery.app-canvas'
                'class': ctrl.mode()
                'config': ctrl.viewConfig
                [
                    m(
                        '.loading.pane'
                        m(
                            '.slate.col-md-offset-3.col-md-6.text-center'
                            [
                                m('h1.animated.fadeIn', [Icon('picture-o')])
                                m('h2', ['Loading'])
                            ]
                        )
                    )
                    m(
                        '.dropzone.pane'
                        ondrop: m.debubble(ctrl.dragDrop)
                        ondragover: ctrl.dragOver
                        ondragenter: m.debubble(ctrl.dragEnter)
                        ondragleave: m.debubble(ctrl.dragLeave)
                        m(
                            '.slate.col-md-offset-3.col-md-6.text-center'
                            [
                                m('h1.animated.fadeInDown', [Icon('cloud-download')])
                                m('h2', ['Drop pictures here to upload'])
                            ]
                        )
                    )
                    m(
                        '.album.pane'
                        ondragenter: m.debubble(ctrl.dragEnter)
                        g.images().map(albumImgTmpl)
                    )
                    m(
                        '.zoomview.pane'
                        ondragenter: m.debubble(ctrl.dragEnter)
                        [
                            if ctrl.focusIndex() isnt 0 then m('.back', {onclick: ctrl.prevImage}, [Icon('angle-left')]) else ''
                            zoomImgTmpl(g.images()[ctrl.focusIndex()], ctrl.focusIndex())
                            if ctrl.focusIndex() isnt g.images().length - 1 then m('.forward', {onclick: ctrl.nextImage}, [Icon('angle-right')]) else ''
                        ]
                    )
                ]
            )
)
