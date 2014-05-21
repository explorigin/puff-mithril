m.factory(
    'pages.home',
    [
        'application.config'
        'helpers.storage'
        'helpers.icon'
    ]
    (cfg, Storage, Icon) ->
        storage = new Storage()

        THEMES =
            'Light': 'bg-light'
            'Dark': 'bg-dark'
            'Night': 'bg-black'
            'Barney': 'bg-primary'

        fullScreenIf = (conditional) ->
            (el, isInit) ->
                if conditional()
                    for platform in ['r', 'webkitR', 'mozR', 'msR']
                        attr = platform + 'equestFullscreen'
                        if typeof document.body[attr] is 'function'
                            document.body[attr]()
                            break
                    conditional(false)

        toggle = (prop) ->
            return (evt) ->
                prop(not prop())

        controller: () ->
            @theme = m.prop('Light')
            @requestFullScreen = m.prop(false)
            @verticalNav = m.prop(false)
            @showOffScreen = m.prop(false)

            return @

        view: (ctrl) ->
            asideClasses = [
                THEMES[ctrl.theme()]
                if ctrl.verticalNav() then 'nav-vertical' else null
                if ctrl.showOffScreen() then 'nav-off-screen' else null
            ].filter((c) -> c isnt null).join('.')

            [
                m('section.hbox.stretch', {config: fullScreenIf(ctrl.requestFullScreen)}, [
                    m(
                        'aside#nav.aside-md.' + asideClasses
                        [
                            m('section.vbox', [
                                m('header.nav-bar.dker', [
                                    m('a.btn.btn-link.visible-xs', {onclick: toggle(ctrl.showOffScreen)}, [Icon('bars')])
                                    m('a.nav-brand', {onclick: ctrl.requestFullScreen}, ['Puff'])
                                    m('a.btn.btn-link.visible-xs', [Icon('comment-o')])
                                ])
                                m('section.app-menu', [
                                    m('nav.nav-primary.hidden-xs', [
                                        m('ul.nav', cfg.applications.map(
                                            (app) ->
                                                m(
                                                    'li'
                                                    [m(
                                                        'a'
                                                        {href:"##{app.module}"}
                                                        [Icon(app.icon), m('span', [app.name])]
                                                    )]
                                                )
                                            )
                                        )
                                    ])
                                ])
                                m('footer.hidden-xs', [
                                    m('a.btn.btn-link', {onclick: toggle(ctrl.verticalNav)}, [Icon('bars')])
                                    m('a.btn.btn-link.pull-right', {href: cfg.pages.login}, [Icon('power-off')])
                                ])
                            ])
                        ]
                    )
                    m('main#content')
                ])
            ]
)
