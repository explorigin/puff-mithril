m.factory(
    'pages.gallery',
    [
        'application.config'
        'components.gallery-image'
        'helpers.icon'
        'helpers.photo-utils'
    ]
    (cfg, GalleryImage, Icon, PhotoUtils) ->
        scrollBarWidth = PhotoUtils.scrollBarWidth()
        borderSize = 4
        UI_DELAY = 100

        controller: () ->
            window.s = self = @  # window.s for debugging
            containerEl = document.getElementById('content')

            @modeChangeTimeout = m.prop()

            @mode = m.prop('draghover')
            @images = m.prop([])  # Array of Gallery Photo controllers
            @optimalImageHeightRatio = m.prop(3/8)
            @files = m.prop([])  # Incoming files


            # Image sizing properties
            @viewPort =
                width: m.cachedComputed(-> containerEl.clientWidth - scrollBarWidth)
                height: m.cachedComputed(-> containerEl.clientHeight)

            refreshDimensions = (evt) ->
                setTimeout(
                    ->
                        self.viewPort.width.refresh()
                        self.viewPort.height.refresh()
                        self.resizeImages()
                        m.redraw()
                    0
                )

            @resizeSubscription = window.addEventListener('resize', refreshDimensions)
            @onunload = -> window.removeEventListener('resize', refreshDimensions)

            @optimalImageHeight = -> self.viewPort.height() * @optimalImageHeightRatio()

            @totalOptimalImageWidth = ->
                optimalHeight = @optimalImageHeight()
                @images().reduce(
                    (sum, i) -> sum + i.aspectRatio() * optimalHeight
                    0
                )

            @rowCount = ->
                Math.ceil(@totalOptimalImageWidth() / @viewPort.width())

            @positionWeights = ->
                @images().map((i) -> i.aspectRatio() * 100)

            @partitions = ->
                partition(@positionWeights(), @rowCount())

            resizeImageLock = null
            @resizeImages = ->
                if resizeImageLock isnt null
                    return resizeImageLock.promise

                resizeImageLock = m.deferred()

                rows = @partitions()
                promises = []
                index = 0
                for row in rows
                    # Linear partition will inject empty rows to complete the mathmatic equation.  Here we just ignore those rows.
                    break unless row.length > 0

                    summedAspectRatios = row.reduce(((sum, ar) -> sum + ar), 0)
                    modifiedWidth = @viewPort.width() / summedAspectRatios * 100
                    endPoint = row.length - 1 + index
                    for img_index in [index..endPoint]
                        img = @images()[img_index]
                        ar = img.aspectRatio()
                        max_width = (modifiedWidth - borderSize) * ar
                        max_height = modifiedWidth - borderSize
                        promises.push(img.small_img.refresh('async', max_width, max_height))

                    index += row.length

                m.sync(promises).then(
                    () ->
                        m.redraw()
                        r = resizeImageLock
                        resizeImageLock = null
                        r.resolve(promises.length)
                    (err) ->
                        console.log(err)
                        r = resizeImageLock
                        resizeImageLock = null
                        r.reject(err)
                )

                return resizeImageLock.promise

            # Drag & Drop functions
            @importNextFile = ->
                # Read the top file.
                return unless file = self.files().shift()

                img = new GalleryImage.controller()
                img.readAsDataURL(file).then(
                    (img) ->
                        # Grab the md5 precomputed hashes of the existing images
                        imageHashes = _.pluck(self.images(), 'md5').map((md5) -> md5())
                        # If the image is not already in the group, then add it and resize all the images.
                        if img.md5() not in imageHashes
                            self.images().push(img)
                            return self.resizeImages()
                    (err) ->
                        console.log(err)
                        setTimeout(self.importNextFile, UI_DELAY)
                ).then(
                    (added) ->
                        m.redraw()
                        setTimeout(self.importNextFile, UI_DELAY) unless added is 0
                    (err) ->
                        console.log(err)
                        setTimeout(self.importNextFile, UI_DELAY)
                )

            @dragDrop = (evt) ->
                # Filter for just our image files
                self.files(_.filter(evt.dataTransfer.files, (f) -> f.type.indexOf('image/') is 0))
                # Give a delay for the UI to update between image loads.
                setTimeout(self.importNextFile, UI_DELAY)

                # We're finished dropping, go back to gallery mode to display images as they come in.
                self.mode('album')
                return false

            @dragEnter = (evt) ->
                self.mode('draghover')
                if self.modeChangeTimeout()
                    clearTimeout(self.modeChangeTimeout())
                    self.modeChangeTimeout(null)

            @dragLeave = (evt) ->
                self.modeChangeTimeout(
                    setTimeout(
                        -> self.mode('album')
                        100
                    )
                )

            @dragOver = (evt) =>
                # This is needed to tell the browser that the element can accept a drop.
                evt.preventDefault()

            return @

        view: (ctrl) ->
            m(
                '.gallery.app-canvas'
                [
                    m(
                        '.dropzone.pane'
                        'class': ctrl.mode()
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
                        '.images.pane'
                        'class': ctrl.mode()
                        ondragenter: m.debubble(ctrl.dragEnter)
                        ctrl.images().map(GalleryImage.view)
                    )
                ]
            )
)
