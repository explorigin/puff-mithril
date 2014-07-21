m.factory(
    'pages.notes',
    [
        'application.config'
        'helpers.icon'
    ]
    (cfg, Icon) ->
        controller: () ->
            return @

        view: (ctrl) ->
            m('iframe.notes.app-canvas', {src: '/notes/'})
)
