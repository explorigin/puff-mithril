###* @jsx m ###
((m) ->
    m.factory(
        'pages.index'
        ['application.config', 'components.form', 'components.panel']
        (cfg, Form, Panel, showPromise) ->
            controller: () ->
                @showLoginForm = m.prop(false)

                showPromise.then(() =>
                    m.startComputation()
                    ret = @showLoginForm(true)
                    m.endComputation()
                )

                @submit = (evt) =>
                    evt.preventDefault()
                    alert('Oh look, you found my login form. Good for you.')
                    @showLoginForm(false)
                return @

            view: (ctrl) ->
                Panel(
                    {'class': if ctrl.showLoginForm() then 'animated slideInDown' else 'hidden'}
                    Form(
                        elements: [
                            {
                                placeholder: 'Username'
                                name: 'username'
                                autofocus: 'autofocus'
                            },
                            {
                                placeholder: 'Password'
                                name: 'pw'
                                type: 'password'
                            },
                            {
                                text: 'Login'
                                type: 'submit'
                            }
                        ]
                        'class': 'form-inline'
                        onsubmit: ctrl.submit
                    )
                )
    )
)(Mithril)
