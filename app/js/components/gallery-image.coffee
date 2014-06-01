# components/gallery-image.js
m.factory(
    'components.gallery-image'
    [
        'helpers.photo-utils'
    ]
    (PhotoUtils) ->
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
            @progress = m.prop(0)
            @progressMax = m.prop(0)

            # Image properties
            @width = m.prop(initialWidth)
            @height = m.prop(initialHeight)
            @original = m.prop(null)
            @mimetype = m.prop('image/*')
            @filename = m.prop('[unnamed]')
            @lastModifiedDate = m.prop(new Date())
            @aspectRatio = -> @width() / @height()

            # Computed Image Properties
            @img = m.cachedComputed( ->
                if self.original() is null
                    return null
                return PhotoUtils.resize(self.original(), screen.width(), screen.height())
            )

            @small_img = m.cachedComputed((width, height) ->
                if self.img() is null
                    return null
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

                readerOnloadStart = (evt) ->
                    self.progressMax(evt.total)

                    m.redraw()

                readerProgress = (evt) ->
                    self.progress(evt.loaded)
                    m.redraw()

                readerOnload = (evt) ->
                    self.progress(evt.total)
                    img = new Image()
                    img.onload = imgOnload
                    img.src = evt.target.result

                imgOnload = (evt) ->
                    img = evt.target
                    self.original(img)
                    self.img.refresh()

                    self.md5.refresh()
                    self.small_img.refresh(
                        'async'
                        Math.floor(initialWidth)
                        Math.floor(initialWidth / (img.width / img.height))
                    ).then(
                        () ->
                            self.mode('ready')
                            m.redraw()
                            de = d
                            d = null
                            de.resolve(self)
                    )

                reader = new FileReader()
                reader.onloadstart = readerOnloadStart
                reader.onprogress = readerProgress
                reader.onload = readerOnload
                reader.readAsDataURL(file)

                @mimetype(file.type)
                @filename(file.name)
                @lastModifiedDate(file.lastModifiedDate)

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
