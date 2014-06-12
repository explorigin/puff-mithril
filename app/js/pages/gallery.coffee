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

        controller: () ->
            window.s = self = @  # window.s for debugging
            containerEl = document.getElementById('content')

            @mode = m.prop('draghover')
            @images = m.prop([])  # Array of Gallery Photo controllers
            @optimalImageHeightRatio = m.prop(3/10)


            # Image sizing properties
            @viewPort =
                width: m.cachedComputed(
                    ->
                        containerEl.clientWidth - scrollBarWidth
                    )
                height: m.cachedComputed(
                    ->
                        containerEl.clientHeight
                    )

            refreshDimensions = (evt) ->
                self.viewPort.width.refresh()
                self.viewPort.height.refresh()
                self.resizeImages()
                m.redraw()

            @resizeSubscription = window.addEventListener('resize', refreshDimensions)
            @onunload = -> window.removeEventListener('resize', refreshDimensions)

            @optimalImageHeight = -> Math.round(self.viewPort.height() * @optimalImageHeightRatio())

            @totalOptimalImageWidth = ->
                optimalHeight = @optimalImageHeight()
                @images().reduce(
                    (sum, i) ->
                        sum + i.aspectRatio() * optimalHeight
                    0
                )

            @rowCount = ->
                Math.ceil(@totalOptimalImageWidth() / @viewPort.width())

            @positionWeights = ->
                @images().map(
                    (i) ->
                        Math.round(i.aspectRatio())
                )

            @partitions = ->
                partition(@positionWeights(), @rowCount())

            resizeImageLock = false
            @resizeImages = ->
                if resizeImageLock is true
                    return
                resizeImageLock = true

                rows = @partitions()
                if rows.length < 0
                    for img in @images()
                        img.width(Math.floor(@optimalImageHeight() * img.aspectRatio()))
                        img.height(Math.floor(@optimalImageHeight()))
                        img.small_img.clear()
                        img.small_img.refresh()
                        m.redraw()
                        resizeImageLock = false
                else
                    index = 0
                    imgs = []
                    for row in rows
                        # Linear partition will inject empty rows to complete the mathmatic equation.  Here we just ignore those rows.
                        break unless row.length > 0

                        summedAspectRatios = row.reduce(((sum, ar) -> sum + ar), 0)
                        modifiedWidth = @viewPort.width() / summedAspectRatios
                        endPoint = row.length - 1 + index
                        for img_index in [index..endPoint]
                            img = @images()[img_index]
                            ar = img.aspectRatio()
                            img.width(Math.floor(modifiedWidth) - borderSize)
                            img.height(Math.floor(modifiedWidth / ar) - borderSize)
                            imgs.push(img)

                        index += row.length
                    imgs = imgs.map(
                        (i) ->
                            i.small_img.clear()
                            i.small_img.refresh('async')
                    )
                    m.sync(imgs).then(
                        () ->
                            m.redraw()
                            resizeImageLock = false
                        () ->
                            console.log('fail')
                    )

            # Drag & Drop functions
            @dragDrop = (evt) ->
                imgs = []

                for file, i in evt.dataTransfer.files
                    img = new GalleryImage.controller()
                    self.images().push(img)
                    imgs.push(img.readAsDataURL(file))

                m.sync(imgs).then(
                    () ->
                        # Remove duplicate images
                        images = self.images()
                        imageHashes = images.map((img) -> img.md5())
                        for img_index in [images.length-1..0]
                            if imageHashes.indexOf(images[img_index].md5()) isnt img_index
                                self.images().splice(img_index, 1)

                        self.resizeImages()
                )

                self.mode('gallery')
                return false

            @dragEnter = (evt) =>
                @mode('draghover')

            @dragLeave = (evt) =>
                @mode('gallery')

            @dragOver = (evt) =>
                # This is needed to tell the browser that the element can accept a drop.
                evt.preventDefault()

            return @

        view: (ctrl) ->
            modes =
                gallery: ctrl.images().map(GalleryImage.view)
                draghover: m('.slate.col-md-offset-3.col-md-6.text-center', [
                    m('h1.animated.fadeInDown', [Icon('cloud-download')])
                    m('h2', ['Drop pictures here to upload'])
                ])
            m(
                '.gallery-canvas'
                {
                    ondrop: m.debubble(ctrl.dragDrop)
                    ondragover: ctrl.dragOver
                    ondragenter: m.debubble(ctrl.dragEnter)
                    ondragleave: m.debubble(ctrl.dragLeave)
                }
                modes[ctrl.mode()]
            )
)
