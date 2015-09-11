m = require('mithril')
cfg = require('config')
Icon = require('helpers/icon')
Gallery = require('models/gallery')
partition = require('external/linear_partition')

borderSize = cfg.apps.gallery.borderSize
currentGallery = null
clearGalleryTimeout = null

module.exports =
    controller: () ->
        self = @  # window.s for debugging

        @gallery = m.prop(currentGallery or new Gallery())
        @mode = m.prop('loading')
        @modeChangeTimeout = m.prop()
        @focusIndex = m.prop(null)

        refreshDimensions = (evt) ->
            # Defer refreshing the container dimensions so we know that the container has resized
            setTimeout(
                ->
                    m.startComputation()
                    self.gallery().resizeImages().then(m.endComputation)
                0
            )
        @resizeSubscription = window.addEventListener('resize', refreshDimensions)
        @onunload = ->
            window.removeEventListener('resize', refreshDimensions)

            # After 30 seconds allow the gallery to be garbage collected
            clearGalleryTimeout = setTimeout(
                ->
                    clearGalleryTimeout = null
                    currentGallery = null
                30000
            )

        # Event Interactions
        @toggleFocusOnImage = (index) ->
            ->
                if self.focusIndex() == index
                    index = null
                self.focusIndex(index)
                self.mode(if index is null then 'grid' else 'showcase')

        @removeImage = (index) ->
            ->
                album = self.gallery().activeAlbum()
                if self.focusIndex() == index
                    self.focusIndex(null)
                album.images().splice(index, 1)
                album.save().then(
                    ->
                        img = self.gallery().images().splice(index, 1)
                        img[0].remove()
                ).then(
                    ->
                        if album.images().length
                            self.mode('grid')
                            self.gallery().resizeImages()
                        else
                            self.mode('draghover')
                )


                self.gallery().activeAlbum().save()

        @dragDrop = (evt) ->
            self.gallery().importFiles(evt.dataTransfer.files)

            # We're finished dropping, go back to gallery mode to display images as they come in.
            self.mode('grid')
            return false

        @dragEnter = (evt) ->
            setTimeout(
                ->
                    if self.modeChangeTimeout()
                        clearTimeout(self.modeChangeTimeout())
                        self.modeChangeTimeout(null)
                    self.mode('draghover')
                0
            )


        @dragLeave = (evt) ->
            if not self.modeChangeTimeout()
                self.modeChangeTimeout(
                    setTimeout(
                        ->
                            self.modeChangeTimeout(null)
                            self.mode('grid')
                            m.redraw()
                        500
                    )
                )

        @dragOver = (evt) =>
            # This is needed to tell the browser that the element can accept a drop.
            evt.preventDefault()

        @prevImage = ->
            self.focusIndex(Math.max(self.focusIndex() - 1, 0))

        @nextImage = ->
            self.focusIndex(Math.min(self.focusIndex() + 1, self.gallery().images().length - 1))

        @viewConfig = (el, previouslyCreated) ->
            g = self.gallery()
            width = g.containerWidth()
            height = g.containerHeight()

            g.container(el)

            if g.containerWidth() != width or g.containerHeight() != height
                refreshDimensions()

        currentGallery = self.gallery()
        clearTimeout(clearGalleryTimeout) unless clearGalleryTimeout is null

        currentGallery.ready.then(
            () ->
                if currentGallery.images().length
                    self.mode('grid')
                else
                    self.mode('draghover')
                m.redraw()
            (err) ->
                m.log('Error: ' + err)
        )

        return @

    view: (ctrl) ->
        g = ctrl.gallery()

        albumImgTmpl = (img, index) ->
            width = img.width()
            height = img.height()
            src = img.smallImg().src

            [
                m(
                    'img.image'
                    {
                        style: "width: #{width}px; height: #{height}px"
                        src: src
                        onclick: ctrl.toggleFocusOnImage(index)
                    }
                )
                # Icon('times', {'class':'remove', onclick: ctrl.removeImage(index)})
            ]

        zoomImgTmpl = (img, index) ->
            return '' unless img

             # When focusing, maximized the image to the container
            if g.containerAspectRatio() < img.aspectRatio()
                width = g.containerWidth() - borderSize
                height = width / img.aspectRatio()
            else
                height = g.containerHeight() - borderSize
                width = height * img.aspectRatio()

            src = img.screenImg().src

            [
                m(
                    '.image'
                    [
                        m(
                            'img'
                            {
                                style: "width: #{width}px; height: #{height}px"
                                src: src
                                onclick: ctrl.toggleFocusOnImage(index)
                            }
                        )
                        m(
                            '.button_bar'
                            [
                                Icon('times', {'class':'remove', onclick: ctrl.removeImage(index)})
                            ]
                        )
                    ]
                )
            ]


        m(
            '.gallery.app-canvas'
            'class': ctrl.mode()
            'config': ctrl.viewConfig
            [
                m(
                    '.loading.pane'
                    m(
                        '.slate.col-md-offset-3.col-md-6.text-center'
                        [
                            m('h1.animated.fadeIn', [Icon('picture-o')])
                            m('h2', ['Loading'])
                        ]
                    )
                )
                m(
                    '.dropzone.pane'
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
                    '.album.pane'
                    ondragenter: m.debubble(ctrl.dragEnter)
                    g.images().map(albumImgTmpl)
                )
                m(
                    '.zoomview.pane'
                    ondragenter: m.debubble(ctrl.dragEnter)
                    [
                        if ctrl.focusIndex() isnt 0 then m('.back', {onclick: ctrl.prevImage}, [Icon('angle-left')]) else ''
                        zoomImgTmpl(g.images()[ctrl.focusIndex()], ctrl.focusIndex())
                        if ctrl.focusIndex() isnt g.images().length - 1 then m('.forward', {onclick: ctrl.nextImage}, [Icon('angle-right')]) else ''
                    ]
                )
            ]
        )
