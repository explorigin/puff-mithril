m.factory(
    'pages.files',
    [
        'application.config'
        'helpers.icon'
    ]
    (cfg, Icon) ->
        controller: () ->
            return @

        view: (ctrl) ->
            m(
                '.files.app-canvas'
                [
                    m('.slate.col-md-offset-3.col-md-6.text-center', [
                        m('h1', [Icon('road')])
                        m('h2', ['Under construction'])
                    ])
                ]
            )
)
