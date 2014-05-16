# components/form.js
((m) ->
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
                options.role = 'form'

                m('form', m.omit(options, 'elements'), options.elements.map(dispatcher))
    )
)(Mithril)
