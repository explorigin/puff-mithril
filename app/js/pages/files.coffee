m.factory(
    'pages.files',
    [
        'application.config'
        'helpers.storage'
        'helpers.icon'
    ]
    (cfg, Storage, Icon) ->
        storage = new Storage()

        controller: () ->
            return @

        view: (ctrl) ->
            m('.slate.col-md-offset-3.col-md-6.text-center', [
                m('h1', [Icon('road')])
                m('h2', ['Under construction'])
            ])
)
