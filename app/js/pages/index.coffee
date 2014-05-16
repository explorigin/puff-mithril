((m) -> m.factory(
    'pages.index',
    ['application.config', 'components.form', 'components.panel']
    (cfg, Form, Panel) ->
        controller: () ->
            @timeout = m.prop(null)
            @showLoginForm = m.prop(false)

            @mouseover = (evt) =>
                if @showLoginForm() is false
                    @timeout = setTimeout(
                        () =>
                            @showLoginForm(true)
                        3000
                    )

            @mouseout = (evt) =>
                if @showLoginForm() is false
                    clearTimeout(@timeout)

            @submit = (evt) =>
                evt.defaultPrevented = true
                alert('Oh look, you found my login form. Good for you.')
                @showLoginForm(false)
            return @

        view: (ctrl) -> [
            m('section', {'class': 'login'}, [
                m('div', {'class': 'col-md-4 col-md-offset-4'}, [
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
                ])
            ])

            m('div', {'class': 'floater'})

            m('div', {'class': 'centered'}, [
                m('img', {
                    src:'images/cookiemonster.gif'
                    alt:'Waiting Cookie Monster'
                    onmouseover: ctrl.mouseover
                    onmouseout: ctrl.mouseout
                })
            ])

            m('footer', [
                m('ul',
                    cfg.oldLinks.map(
                        (link) ->
                            m('li', [m('a', {href: link.href}, [link.text])])
                    )
                )
            ])
        ]
))(Mithril)
