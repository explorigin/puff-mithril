# helpers/submit.js
m = require('mithril')
Button = require('helpers/button')

module.exports = (options) ->
    options.type = 'submit'
    options['class'] = (options['class'] or '') + 'form-control'
    m('div.form-group', [Button(options)])
