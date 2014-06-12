# components/progressbar.js
m.factory(
    'components.progressbar'
    ->
        controller: () ->
            # State properties
            @progress = m.prop(0)
            @progressMin = m.prop(0)
            @progressMax = m.prop(0)

            # Methods
            @pctProgress = =>
                @progress() / @progressMax() * 100

            @eventStart = (evt) =>
                @progressMax(evt.total)
                m.redraw()

            @eventProgress = (evt) =>
                @progress(evt.loaded)
                m.redraw()

            @eventFinish = (evt) =>
                @progress(evt.total)
                m.redraw()

            return @

        view: (ctrl) ->

            return m(
                '.progress'
                [
                    m(
                        '.progress-bar'
                        {
                            role: 'progressbar'
                            'aria-valuenow': ctrl.progress()
                            'aria-valuemin': ctrl.progressMin()
                            'aria-valuemax': ctrl.progressMax()
                            style: "width: #{ctrl.pctProgress()}%;"
                        }
                        [m('span.sr-only', ["#{ctrl.pctProgress()}% Complete"])]
                    )
                ]
            )
)
