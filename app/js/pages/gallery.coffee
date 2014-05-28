m.factory(
    'pages.gallery',
    [
        'application.config'
        'helpers.storage'
        'helpers.icon'
    ]
    (cfg, Storage, Icon) ->
        storage = new Storage()

        controller: () ->
            self = @
            @mode = m.prop('gallery')
            @images = images = m.prop([])

            @progressMax = m.prop(0)
            @progressList = m.prop([])
            @progress = =>
                @progressList().reduce(((sum, x) -> sum + (x or 0)), 0)

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
                        self.images().push(
                            src: img.src
                            aspectRatio: img.width / img.height
                            width: 500
                        )

                        if self.progress() == self.progressMax()
                            self.mode('gallery')
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
                m('img', img)

            modes =
                gallery: ctrl.images().map(buildImage)
                draghover: m('.slate.col-md-offset-3.col-md-6.text-center', [
                    m('h1.animated.fadeInDown', [Icon('cloud-download')])
                    m('h2', ['Drop pictures here to upload'])
                ])
                import: m('.col-md-offset-3.col-md-6.text-center', [
                    m('progress.progress.progress-striped.active', {max: ctrl.progressMax(), value: ctrl.progress()})
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
