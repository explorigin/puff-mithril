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
            m(
                '.files'
                ['Currently empty']
            )
)
