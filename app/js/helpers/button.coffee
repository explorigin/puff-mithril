# helpers/button.js
m.factory(
    'helpers.button'
    () ->
        (options) ->
            m('div.form-group', [
                m('button.btn.btn-default', m.omit(options, 'text'), options.text)
            ])
)
