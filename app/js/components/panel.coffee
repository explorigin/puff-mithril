# components/panel.js
m.factory(
    'components.panel'
    () ->
        (options, contents) ->
            body = m('.panel-body', [contents])
            header = if options.header then m('header.panel-heading', [options.header]) else ''
            footer = if options.footer then m('footer.panel-footer', [options.footer]) else ''
            options['class'] = 'panel ' + (options['class'] or '')

            m('section', _.omit(options, 'header', 'content', 'footer'), [header, body, footer])
)
