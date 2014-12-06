m = require('mithril')
cfg = require('config')
Icon = require('helpers/icon')

module.exports =
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
