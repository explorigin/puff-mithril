m.factory(
    'pages.home',
    [
        'application.config'
        'helpers.icon'
    ]
    (cfg, Icon) ->

        PubSub.subscribe(
            'REQUEST_FULLSCREEN',
            ->
                for attr in ['requestFullscreen', 'webkitRequestFullscreen', 'mozRequestFullScreen', 'msRequestFullscreen']
                    if typeof document.body[attr] is 'function'
                        document.body[attr]()
                        break
                return null
        )

        PubSub.subscribe(
            'CANCEL_FULLSCREEN',
            ->
                for attr in ['exitFullscreen', 'webkitExitFullscreen', 'mozCancelFullScreen', 'msExitFullscreen']
                    if typeof document[attr] is 'function'
                        document[attr]()
                        break
                return null
        )

        toggleFullScreen = ->
            # Must run sync to work with Mozilla's security
            m.startComputation()
            PubSub.publishSync(if isFullScreen() then 'CANCEL_FULLSCREEN' else 'REQUEST_FULLSCREEN')
            setTimeout(
                ->
                    m.endComputation()
                0
            )

        isFullScreen = ->
            document.fullscreenElement or document.webkitFullscreenElement or document.mozFullScreen or document.msFullscreenElement

        controller: () ->
            @theme = m.prop('Light')
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
                if (ctrl.showOffScreen() or isFullScreen()) then 'nav-off-screen' else null
            ].filter((c) -> c isnt null).join('.')

            [
                m('section.hbox.stretch', [
                    m(
                        'aside#nav.' + asideClasses
                        [
                            m('section.vbox', [
                                m('header.nav-bar.bg-dark', [
                                    m('a.btn.btn-link.visible-xs', {onclick: m.toggle(ctrl.showOffScreen)}, [Icon('bars')])
                                    m('a.nav-brand', {onclick: toggleFullScreen}, ['Puff'])
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
