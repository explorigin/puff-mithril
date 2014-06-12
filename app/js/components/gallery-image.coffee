# components/gallery-image.js
m.factory(
    'components.gallery-image'
    [
        'helpers.photo-utils'
        'components.progressbar'
    ]
    (PhotoUtils, ProgressBar) ->
        initialWidth = 400
        initialHeight = 300

        screen =
            width: m.cachedComputed(
                ->
                    window.screen.width
                )
            height: m.cachedComputed(
                ->
                    window.screen.height
                )

        controller: () ->
            self = @

            # State properties
            @mode = m.prop('loading')
            @progressbar = new ProgressBar.controller()

            # Image properties
            @width = m.prop(initialWidth)
            @height = m.prop(initialHeight)
            @original = m.prop(null)
            @mimetype = m.prop('image/*')
            @filename = m.prop('[unnamed]')
            @lastModifiedDate = m.prop(new Date())
            @aspectRatio = m.prop(1.33)

            # Computed Image Properties
            @img = m.cachedComputed( ->
                if self.original() is null
                    return null
                return PhotoUtils.resize(self.original(), screen.width(), screen.height())
            )

            @small_img = m.cachedComputed((width, height) ->
                if self.img() is null
                    return null

                if self.width() == width and self.height() == height
                    return self.small_img()

                self.width(width or self.width())
                self.height(height or self.height())
                return PhotoUtils.resize(self.img(), self.width(), self.height())
            )

            @md5 = m.cachedComputed( ->
                if self.img() is null
                    return null
                return md5(self.img().src)
            )

            # Methods
            @readAsDataURL = (file) ->
                d = m.deferred()

                readerOnload = (evt) ->
                    img = new Image()
                    img.onload = imgOnload
                    img.src = evt.target.result

                imgOnload = (evt) ->
                    img = evt.target
                    self.aspectRatio(img.width / img.height)
                    self.original(img)
                    self.img.refresh()

                    self.md5.refresh()
                    max_width = Math.floor(initialWidth)
                    max_height = Math.floor(initialWidth / (img.width / img.height))
                    self.small_img.refresh(
                        'async'
                        max_width
                        max_height
                    ).then(
                        () ->
                            self.mode('ready')
                            m.redraw()
                            de = d
                            d = null
                            de.resolve(self)
                    )

                reader = new FileReader()
                reader.onloadstart = self.progressbar.eventStart
                reader.onprogress = self.progressbar.eventProgress
                reader.onload = (evt) ->
                    self.progressbar.eventFinish.apply(@, arguments)
                    readerOnload.apply(@, arguments)
                reader.readAsDataURL(file)

                self.mimetype(file.type)
                self.filename(file.name)
                self.lastModifiedDate(file.lastModifiedDate)

                return d.promise

            return @


        view: (ctrl) ->
            small = ctrl.small_img()
            big = ctrl.img()
            width = ctrl.width()
            height = ctrl.height()

            switch ctrl.mode()
                when 'ready'
                    return m(
                        '.image'
                        {
                            style: "width: #{width}px; height: #{height}px; background-image: url(#{small.src})"
                        }
                    )
                when 'loading'
                    return m(
                        '.image'
                        {
                            style: "width: #{ctrl.width()}px; height: #{ctrl.height()}px"
                        }
                        [m('h2', ['Loading...'])]
                    )
                when 'error'
                    return m(
                        '.image'
                        {
                            style: "width: #{ctrl.width()}px; height: #{ctrl.height()}px"
                        }
                        [m('h2', ['Error...'])]
                    )
                when 'show'
                    return m(
                        '.image'
                        {
                            style: "background-image: url(#{big.src})"
                        }
                    )
)
