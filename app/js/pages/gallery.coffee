m.factory(
    'pages.gallery',
    [
        'application.config'
        'models.image'
        'helpers.icon'
        'helpers.photo-utils'
    ]
    (cfg, GalleryImage, Icon, PhotoUtils) ->
        scrollBarWidth = PhotoUtils.scrollBarWidth()
        borderSize = 4
        UI_DELAY = 20

        containerEl = document.getElementById('content')

        viewPort =
            width: m.cachedComputed(-> containerEl.clientWidth - scrollBarWidth)
            height: m.cachedComputed(-> containerEl.clientHeight)
            aspectRatio: -> viewPort.width() / viewPort.height()

        Gallery = ->
            self = @
            resizeImageLock = null

            # Properties
            @images = m.prop([])  # Array of Gallery Photo controllers
            @optimalImageHeightRatio = m.prop(3/8)
            @files = m.prop([])  # Incoming files

            # Computed Properties
            @optimalImageHeight = -> viewPort.height() * @optimalImageHeightRatio()

            @totalOptimalImageWidth = ->
                optimalHeight = @optimalImageHeight()
                @images().reduce(
                    (sum, i) -> sum + i.aspectRatio() * optimalHeight
                    0
                )

            @partitions = ->
                rowCount = Math.ceil(@totalOptimalImageWidth() / viewPort.width())
                partition(@images().map((i) -> i.aspectRatio() * 100), rowCount)

            # Methods
            @resizeImages = ->
                if resizeImageLock isnt null
                    return resizeImageLock.promise

                resizeImageLock = m.deferred()

                rows = @partitions()
                index = 0
                total = 0
                vpWidth = viewPort.width() * 100
                for row in rows
                    # Linear partition will inject empty rows to complete the mathmatic equation.  Here we just ignore those rows.
                    break unless row.length > 0

                    summedAspectRatios = row.reduce(((sum, ar) -> sum + ar), 0)
                    modifiedWidth = vpWidth / summedAspectRatios
                    endPoint = row.length - 1 + index
                    for img_index in [index..endPoint]
                        img = @images()[img_index]
                        img.small_img.refresh(
                            (modifiedWidth - borderSize) * img.aspectRatio()
                            modifiedWidth - borderSize
                        ).then(m.redraw)
                        total += 1

                    index += row.length

                r = resizeImageLock
                resizeImageLock = null
                r.resolve(total)

                return r.promise

            importNextFile = ->
                # Read the top file.
                return unless file = self.files().shift()

                img = new GalleryImage()
                img.read(file).then(
                    (img) ->
                        # Grab the md5 precomputed hashes of the existing images
                        imageHashes = _.pluck(self.images(), 'md5').map((md5) -> md5())
                        # If the image is not already in the group, then add it and resize all the images.
                        if img.md5() not in imageHashes
                            self.images().push(img)
                            return self.resizeImages()
                    (err) ->
                        console.log(err)
                        setTimeout(importNextFile, UI_DELAY)
                ).then(
                    (added) ->
                        m.redraw()
                        setTimeout(importNextFile, UI_DELAY) unless added is 0
                    (err) ->
                        console.log(err)
                        setTimeout(importNextFile, UI_DELAY)
                )

            @importFiles = (files) ->
                # Filter for just our image files
                self.files(_.filter(files, (f) -> f.type.indexOf('image/') is 0))
                # Give a delay for the UI to update between image loads.
                setTimeout(importNextFile, UI_DELAY)

            return @

        controller: () ->
            window.s = self = @  # window.s for debugging

            @gallery = m.prop(new Gallery())
            @mode = m.prop('draghover')
            @modeChangeTimeout = m.prop()
            @focusIndex = m.prop(null)

            refreshDimensions = (evt) ->
                # Defer refreshing the viewport dimensions so we know that the container has resized
                setTimeout(
                    ->
                        m.startComputation()
                        m.sync([
                            viewPort.width.refresh()
                            viewPort.height.refresh()
                        ]).then(->
                            self.gallery().resizeImages().then(m.endComputation)
                        )
                    0
                )
            @resizeSubscription = window.addEventListener('resize', refreshDimensions)
            @onunload = -> window.removeEventListener('resize', refreshDimensions)

            # Event Interactions
            @toggleFocusOnImage = (index) ->
                ->
                    if self.focusIndex() == index
                        index = null
                    self.focusIndex(index)

            @dragDrop = (evt) ->
                self.gallery().importFiles(evt.dataTransfer.files)

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
            g = ctrl.gallery()
            imgTmpl = (img, index) ->
                if ctrl.focusIndex() is index
                    if viewPort.aspectRatio() < img.aspectRatio()
                        width = viewPort.width() - borderSize
                        height = width / img.aspectRatio()
                    else
                        height = viewPort.height() - borderSize
                        width = height * img.aspectRatio()
                    src = img.img().src
                    cls = 'focused slate'
                else
                    width = img.width()
                    height = img.height()
                    src = img.small_img().src
                    cls = if ctrl.focusIndex() is null then '' else 'hidden'
                m(
                    '.image'
                    {
                        style: "width: #{width}px; height: #{height}px; background-image: url(#{src})"
                        'class': cls
                        onclick: ctrl.toggleFocusOnImage(index)
                    }
                )

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
                        g.images().map(imgTmpl)
                    )
                ]
            )
)
