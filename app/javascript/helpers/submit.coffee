# helpers/submit.js
require('mithril')
require('helpers/button')

m.factory(
    'helpers.submit'
    ['helpers.button']
    (Button) ->
        (options) ->
            options.type = 'submit'
            options['class'] = (options['class'] or '') + 'form-control'
            m('div.form-group', [Button(options)])
)
