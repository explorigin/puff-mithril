# components/progressbar.js
m.factory(
    'components.progressbar'
    ->
        UIprop = m.wrappedProp(m.startComputation, m.endComputation)

        controller: () ->
            self = @

            # State properties
            @progress = UIprop(0)
            @progressMin = UIprop(0)
            @progressMax = UIprop(1)

            # Methods
            @pctProgress = ->
                self.progress() / self.progressMax() * 100

            @eventStart = (evt) ->
                self.progressMax(evt.total)

            @eventProgress = (evt) ->
                self.progress(evt.loaded)

            @eventFinish = (evt) ->
                self.progress(evt.total)

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
