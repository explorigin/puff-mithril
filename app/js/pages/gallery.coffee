m.factory(
    'pages.gallery',
    [
        'application.config'
        'helpers.progressbar'
        'helpers.icon'
        'helpers.photo-utils'
    ]
    (cfg, ProgressBar, Icon, PhotoUtils) ->
        controller: () ->
            window.s = self = @
            containerEl = document.getElementById('content')

            @mode = m.prop('draghover')
            @images = m.prop([])


            # Image sizing properties
            @viewPort =
                width: m.cachedComputed(
                    ->
                        containerEl.clientWidth - 16 # to account for a scrollbar
                    )
                height: m.cachedComputed(
                    ->
                        containerEl.clientHeight
                    )

            refreshDimensions = (evt) ->
                self.viewPort.width.refresh()
                self.viewPort.height.refresh()
                m.redraw()

            @resizeSubscription = window.addEventListener('resize', refreshDimensions)
            @onunload = -> window.removeEventListener('resize', refreshDimensions)

            @optimalImageHeight = -> Math.floor(self.viewPort.height() * 2/5)

            @totalOptimalImageWidth = ->
                optimalHeight = @optimalImageHeight()
                @images().reduce(
                    (sum, i) ->
                        sum + i.aspectRatio * optimalHeight
                    0
                )

            @rowCount = ->
                Math.ceil(@totalOptimalImageWidth() / @viewPort.width())

            @positionWeights = ->
                @images().map(
                    (i) ->
                        Math.round(i.aspectRatio)
                )

            @partitions = ->
                partition(@positionWeights(), @rowCount())

            @resizeImages = ->
                index = 0
                for row in @partitions()
                    console.log('row = ' + row)
                    summedAspectRatios = row.reduce(((sum, ar) -> sum + ar), 0)
                    console.log('summedAspectRatios = ' + summedAspectRatios)
                    modifiedWidth = @viewPort.width() / summedAspectRatios
                    for img_index in [index..row.length + index - 1]
                        img = @images()[img_index]
                        console.log("index: #{img_index}, aspectRatio: #{img.aspectRatio}")
                        img.small_src = PhotoUtils.resize(
                            img.big_src
                            Math.floor(modifiedWidth)
                            Math.floor(modifiedWidth * img.aspectRatio)
                        )
                        #console.log(Math.floor(modifiedWidth * img.aspectRatio) + " x " + Math.floor(modifiedWidth))

                    index += row.length


            # Progress Bar properties
            @progressMax = m.prop(0)
            @progressList = m.prop([])
            @progress = =>
                @progressList().reduce(((sum, x) -> sum + (x or 0)), 0)


            # Drag & Drop functions
            @dragDrop = (evt) ->
                # Initialize our progress bar.
                self.progressMax(0)
                self.progressList(new Array(evt.dataTransfer.files.length))
                self.mode('import')

                for file, i in evt.dataTransfer.files
                    fileOnloadStart = (file_evt) ->
                        self.progressMax(self.progressMax() + file_evt.total)
                        m.redraw()

                    fileProgress = (file_evt) ->
                        self.progressList()[@index] = file_evt.loaded
                        m.redraw()

                    fileOnload = (file_evt) ->
                        img = new Image()
                        img.onload = imgOnload
                        img.src = file_evt.target.result
                        self.progressList()[@index] = file_evt.total
                        m.redraw()

                    imgOnload = (img_evt) ->
                        img = img_evt.target

                        small_img = PhotoUtils.resize(img, 1000, self.optimalImageHeight())

                        self.images().push(
                            small_src: small_img
                            big_src: img
                            aspectRatio: small_img.width / small_img.height
                            mimetype: 'image/jpeg'
                            quality: 0.7
                        )

                        if self.progress() == self.progressMax()
                            self.mode('gallery')
                        self.resizeImages()
                        m.redraw()

                    reader = new FileReader()
                    reader.onloadstart = fileOnloadStart
                    reader.onprogress = fileProgress.bind(index: i)
                    reader.onload = fileOnload.bind(index: i)
                    reader.readAsDataURL(file)

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
            buildImage = (img) ->
                m(
                    'img'
                    {
                        src: img.small_src.src
                    }
                )

            modes =
                gallery: ctrl.images().map(buildImage)
                draghover: m('.slate.col-md-offset-3.col-md-6.text-center', [
                    m('h1.animated.fadeInDown', [Icon('cloud-download')])
                    m('h2', ['Drop pictures here to upload'])
                ])
                import: m('.slate.col-md-offset-3.col-md-6.text-center', [
                    ProgressBar(ctrl.progress(), ctrl.progressMax())
                    m('h2', ['Uploading pictures...'])
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
