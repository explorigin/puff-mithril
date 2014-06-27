# models/image.js
m.factory(
    'models.image'
    [
        'helpers.photo-utils'
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

        # Image model
        return ->
            self = @

            # Image properties
            @blob = m.prop(null)
            @original = m.prop(null)
            @width = m.prop(initialWidth)
            @height = m.prop(initialHeight)
            @mimetype = m.prop('image/*')
            @filename = m.prop('[unnamed]')
            @lastModifiedDate = m.prop(new Date())
            @aspectRatio = m.prop(1.33)

            # Computed Image Properties
            @img = m.cachedComputed( ->
                if self.original() is null
                    return null

                d = m.deferred()

                img = PhotoUtils.resize(self.original(), screen.width(), screen.height())
                img.onload = ->
                    d.resolve(img)
                return d.promise
            )

            @small_img = m.cachedComputed((width, height) ->
                if self.img() is null
                    return null

                if self.width() == width and self.height() == height and self.small_img()
                    return self.small_img()

                d = m.deferred()

                self.width(width or self.width())
                self.height(height or self.height())
                img = PhotoUtils.resize(self.img(), self.width(), self.height())
                img.onload = ->
                    d.resolve(img)
                return d.promise
            )

            @md5 = m.cachedComputed( ->
                if self.original() is null
                    return null
                return md5(self.original().src)
            )

            # Methods
            @read = (file) ->
                d = m.deferred()

                imgOnload = (evt) ->
                    img = evt.target
                    self.aspectRatio(img.width / img.height)
                    self.original(img)
                    self.img.refresh().then(->
                        self.md5.refresh()
                    ).then(->
                        # Remove original to conserve a little memory
                        self.original(null)
                        self.small_img.refresh(
                            Math.floor(initialWidth)
                            Math.floor(initialWidth / (img.width / img.height))
                        )
                    ).then(->
                        de = d
                        d = null
                        de.resolve(self)
                    )

                img = new Image()
                img.onload = imgOnload
                img.src = window.URL.createObjectURL(file)
                self.blob(file)

                self.mimetype(file.type)
                self.filename(file.name)
                self.lastModifiedDate(file.lastModifiedDate)

                return d.promise

            return @
)
