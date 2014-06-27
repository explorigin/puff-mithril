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
            width: ->
                window.screen.width
            height: ->
                window.screen.height


        # Image model
        return ->
            self = @

            # Image properties
            @blob = m.prop(null)
            @original = m.prop(null)
            @img = m.prop(null)
            @smallImg = m.prop(null)
            @hash = m.prop(null)
            @width = m.prop(initialWidth)
            @height = m.prop(initialHeight)
            @mimetype = m.prop('image/*')
            @filename = m.prop('[unnamed]')
            @lastModifiedDate = m.prop(new Date())
            @aspectRatio = m.prop(1.33)

            # Computed Image Properties
            @resizeImg = ->
                d = m.deferred()

                if self.original() is null
                    d.reject(new Error('No original image exists to build img from.'))

                img = PhotoUtils.resize(self.original(), screen.width(), screen.height())
                img.onload = ->
                    self.img(img)
                    d.resolve(img)
                return d.promise

            @resizeSmallImg = (width, height) ->
                d = m.deferred()

                if self.img() is null
                    d.reject(new Error('No img exists to build smallImg from.'))

                self.width(width or self.width())
                self.height(height or self.height())
                img = PhotoUtils.resize(self.img(), self.width(), self.height())
                img.onload = ->
                    self.smallImg(img)
                    d.resolve(img)
                return d.promise

            @updateHash = ->
                if self.original() is null
                    return null
                return self.hash(md5(self.original().src))

            # Methods
            @read = (file) ->
                d = m.deferred()

                imgOnload = (evt) ->
                    img = evt.target
                    self.aspectRatio(img.width / img.height)
                    self.original(img)
                    self.resizeImg().then(->
                        self.updateHash()
                    ).then(->
                        # Remove original to conserve a little memory
                        self.original(null)
                        self.resizeSmallImg(
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
