# helpers/submit.js
((m) ->
    m.factory(
        'helpers.submit'
        () ->
            (options) ->
                options.type = 'submit'
                options['class'] = (options['class'] or '') + 'form-control btn btn-default'

                m('div.form-group', [
                    m('button', m.omit(options, 'label', 'helptext', 'text'), options.text)
                ])
    )
)(Mithril)
