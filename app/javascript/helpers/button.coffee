# helpers/button.js
m = require('mithril')
Icon = require('helpers/icon')

module.exports = (options) ->
    text = options.text
    if options.icon
        if options.icon.orientation is 'right'
            text = [text+' ', Icon(options.icon.type, 'orientation')]
        else
            text = [Icon(options.icon.type, 'orientation'), ' '+text]

    m('button.btn.btn-default', m.omit(options, 'text', 'icon'), text)
