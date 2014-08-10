require('mithril')
require('config')
require('helpers/icon')

m.factory(
    'apps.notes',
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
