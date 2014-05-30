# components/form.js
m.factory(
    'components.form'
    ['helpers.input', 'helpers.submit']
    (Input, Submit) ->
        elMap =
            'text': Input
            'email': Input
            'password': Input
            'submit': Submit

        dispatcher = (el) ->
            elMap[el.type or 'text'](el)

        (options) ->
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

            m('form', _.omit(options, 'elements'), options.elements.map(dispatcher))
)
