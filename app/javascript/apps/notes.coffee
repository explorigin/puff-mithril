m = require('mithril')
cfg = require('config')
Icon = require('helpers/icon')

module.exports =
    controller: () ->
        return @

    view: (ctrl) ->
        m('iframe.notes.app-canvas', {src: '/notes/'})
