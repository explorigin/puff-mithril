# components/form.js
m = require('mithril')
Input = require('helpers/input')
Submit = require('helpers/submit')

elMap =
    'text': Input
    'email': Input
    'password': Input
    'submit': Submit

dispatcher = (el) ->
    elMap[el.type or 'text'](el)

module.exports = (options) ->
    oldSubmit = null
    options.role = 'form'

    if typeof options.onsubmit is 'function'
        oldSubmit = options.onsubmit
        options.onsubmit = (evt) ->
            data = {}
            Array.prototype.map.call(
                evt.target
                (el) ->
                    # FIXME - there is probably a bug here dealing with radiobuttons and checkboxes
                    if el.name
                        data[el.name] = el.value
            )
            oldSubmit(evt, data)

    m('form', m.omit(options, 'elements'), options.elements.map(dispatcher))
