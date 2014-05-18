###* @jsx m ###

# components/panel.js
m.factory(
    'components.panel'
    () ->
        (options, contents) ->
            body = `<div class="panel-body">{contents}</div>`
            header = if options.header then `<header class="panel-heading">{options.header}</header>` else ''
            footer = if options.footer then `<footer class="panel-footer">{options.footer}</footer>` else ''
            options['class'] = 'panel ' + (options['class'] or '')

            m('section', m.omit(options, 'header', 'content', 'footer'), [header, body, footer])
)
