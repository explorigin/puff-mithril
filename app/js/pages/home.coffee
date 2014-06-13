m.factory(
    'pages.home',
    [
        'application.config'
        'helpers.storage'
        'helpers.icon'
    ]
    (cfg, Storage, Icon) ->
        storage = new Storage()

        fullScreenIf = (conditional) ->
            (el, isInit) ->
                if conditional()
                    for platform in ['r', 'webkitR', 'mozR', 'msR']
                        attr = platform + 'equestFullscreen'
                        if typeof document.body[attr] is 'function'
                            document.body[attr]()
                            break
                    conditional(false)

        controller: () ->
            @theme = m.prop('Light')
            @requestFullScreen = m.prop(false)
            @verticalNav = m.prop(false)
            @showOffScreen = m.prop(false)

            @closeOffScreen = =>
                @showOffScreen(false)
                return true

            @toggleVerticalNav = =>
                @verticalNav(not @verticalNav())

                # trigger the window resize event so other parts of the page know to check for changes.
                evt = document.createEvent('UIEvents')
                evt.initUIEvent('resize', true, false, window, 0)
                window.dispatchEvent(evt)

            return @

        view: (ctrl) ->
            asideClasses = [
                cfg.THEMES[ctrl.theme()]
                if ctrl.verticalNav() then 'nav-vertical' else null
                if ctrl.showOffScreen() then 'nav-off-screen' else null
            ].filter((c) -> c isnt null).join('.')

            [
                m('section.hbox.stretch', {config: fullScreenIf(ctrl.requestFullScreen)}, [
                    m(
                        'aside#nav.aside-md.' + asideClasses
                        [
                            m('section.vbox', [
                                m('header.nav-bar.bg-dark', [
                                    m('a.btn.btn-link.visible-xs', {onclick: m.toggle(ctrl.showOffScreen)}, [Icon('bars')])
                                    m('a.nav-brand', {onclick: ctrl.requestFullScreen}, ['Puff'])
                                    m('a.btn.btn-link.visible-xs', [Icon('comment-o')])
                                ])
                                m('section.app-menu', [
                                    m('nav.nav-primary.hidden-xs', [
                                        m('ul.nav', cfg.applications.map(
                                            (app) ->
                                                m(
                                                    'li'
                                                    {
                                                        'class': (if m.route() is app.module then 'active' else '')
                                                    }
                                                    [m(
                                                        "a[href=##{app.module}]"
                                                        onclick: ctrl.closeOffScreen
                                                        [Icon(app.icon), m('span', [app.name])])]
                                                )
                                            )
                                        )
                                    ])
                                ])
                                m('footer.hidden-xs', [
                                    m('a.btn.btn-link', {onclick: ctrl.toggleVerticalNav}, [Icon('bars')])
                                    m('a.btn.btn-link.pull-right', {href: cfg.pages.login}, [Icon('power-off')])
                                ])
                            ])
                        ]
                    )
                    m('main#content')
                ])
            ]
)
