m.factory(
    'pages.index',
    [
        'application.config',
        'components.form'
        'components.panel'
        'helpers.storage'
    ]
    (cfg, Form, Panel, Storage) ->
        USER_INPUT = 'u'
        CHECKING = 'c'
        NOT_VALID = 'n'
        NOT_SHOWN = 'ns'

        storage = new Storage()

        controller: () ->
            @timeout = m.prop(null)
            @status = m.prop(NOT_SHOWN)

            @mouseover = (evt) =>
                if @status() is NOT_SHOWN
                    @timeout = setTimeout(
                        () =>
                            @status(USER_INPUT)
                        3000
                    )

            @mouseout = (evt) =>
                if @status() is NOT_SHOWN
                    clearTimeout(@timeout)

            @submit = (evt, data) =>
                evt.preventDefault()
                @status(CHECKING)
                storage.account.signIn(data.username, data.password).then(
                    () ->
                        window.location = cfg.pages.home
                    () =>
                        @status(NOT_VALID)
                )

            return @

        view: (ctrl) -> [
            m('section.login', [
                m('.col-md-4.col-md-offset-4', [
                    Panel(
                        {'class': if ctrl.status() is NOT_SHOWN then 'hidden' else 'animated slideInDown'}
                        Form(
                            elements: [
                                {
                                    placeholder: 'Username'
                                    name: 'username'
                                    autofocus: 'autofocus'
                                    disabled: ctrl.status() is CHECKING
                                    validation: if ctrl.status() is NOT_VALID then 'error' else ''
                                    helptext: if ctrl.status() is NOT_VALID then 'Username or password is incorrect.' else ''
                                },
                                {
                                    placeholder: 'Password'
                                    name: 'password'
                                    type: 'password'
                                    validation: if ctrl.status() is NOT_VALID then 'error' else ''
                                    helptext: if ctrl.status() is NOT_VALID then m.trust('&nbsp;') else ''
                                    disabled: ctrl.status() is CHECKING
                                },
                                {
                                    text: 'Login'
                                    type: 'submit'
                                    disabled: ctrl.status() is CHECKING
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
)
