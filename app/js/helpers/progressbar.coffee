# helpers/progressbar.js
m.factory(
    'helpers.progressbar'
    ->
        (progress, max) ->
            pctProgress = progress / max * 100

            m(
                '.progress.progress-striped.active'
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
