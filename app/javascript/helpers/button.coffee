# helpers/button.js
require('mithril')
require('helpers/icon')

m.factory(
    'helpers.button'
    ['helpers.icon']
    (Icon) ->
        (options) ->
            text = options.text
            if options.icon
                if options.icon.orientation is 'right'
                    text = [text+' ', Icon(options.icon.type, 'orientation')]
                else
                    text = [Icon(options.icon.type, 'orientation'), ' '+text]

            m('button.btn.btn-default', m.omit(options, 'text', 'icon'), text)
)
