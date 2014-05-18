# helpers/button.js
((m) ->
    m.factory(
        'helpers.button'
        () ->
            (options) ->
                m('div.form-group', [
                    m('button.btn.btn-default', m.omit(options, 'text'), options.text)
                ])
    )
)(Mithril)
