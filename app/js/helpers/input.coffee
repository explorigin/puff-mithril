# helpers/input.js
m.factory(
    'helpers.input'
    () ->
        (options) ->
            options.type = options.type or 'text'
            options['class'] = (options['class'] or '') + 'form-control'

            if typeof options.onchange is 'function'
                options.onchange = m.withAttr('value', options.onchange)

            m('div.form-group', [
                if options.label then m('label', options.label) else ''
                m('input', m.omit(options, 'label', 'helptext'))
                if options.helptext then m('span.help-block', options.helptext) else ''
            ])
)
