# helpers/progressbar.js
m.factory(
    'helpers.progressbar'
    ->
        (progress, max) ->
            pctProgress = progress / max * 100
            return m(
                '.progress'
                [
                    m(
                        '.progress-bar'
                        {
                            role: 'progressbar'
                            'aria-valuenow': progress
                            'aria-valuemin': 0
                            'aria-valuemax': max
                            style: "width: #{pctProgress}%;"
                        }
                        [m('span.sr-only', ["#{pctProgress}% Complete"])]
                    )
                ]
            )
)
