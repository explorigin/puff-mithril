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
                    return new Image()

                if self.width() == width and self.height() == height
                    return self.small_img()

                self.width(width or self.width())
                self.height(height or self.height())
                return PhotoUtils.resize(self.img(), self.width(), self.height())
            )

            @md5 = m.cachedComputed( ->
                if self.img() is null
                    return new Image()
                return md5(self.img().src)
            )

            # Methods
            @readAsDataURL = (file) ->
                d = m.deferred()

                imgOnload = (evt) ->
                    img = evt.target
                    self.aspectRatio(img.width / img.height)
                    self.original(img)
                    self.img.refresh('async').then(->
                        # Remove original to conserve a little memory
                        self.original(null)
                        self.md5.refresh('async')
                    ).then(->
                        self.small_img.refresh(
                            'async'
                            Math.floor(initialWidth)
                            Math.floor(initialWidth / (img.width / img.height))
                        )
                    ).then(->
                        de = d
                        d = null
                        de.resolve(self)
                    )

                reader = new FileReader()
                reader.onprogress = (evt) -> d.notify(evt.loaded / evt.total)
                reader.onload = (evt) ->
                    img = new Image()
                    img.onload = imgOnload
                    img.src = evt.target.result

                reader.readAsDataURL(file)

                self.mimetype(file.type)
                self.filename(file.name)
                self.lastModifiedDate(file.lastModifiedDate)

                return d.promise

            return @
)
