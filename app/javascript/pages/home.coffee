m = require('mithril')
cfg = require('config')
Signals = require('signals')
Icon = require('helpers/icon')

FilesModule = require('apps/files')
GalleryModule = require('apps/gallery')
NotesModule = require('apps/notes')

Signals.fullscreen.requested.add(
    ->
        for attr in ['requestFullscreen', 'webkitRequestFullscreen', 'mozRequestFullScreen', 'msRequestFullscreen']
            if typeof document.body[attr] is 'function'
                document.body[attr]()
                break
        return null
)

Signals.fullscreen.cancelled.add(
    ->
        for attr in ['exitFullscreen', 'webkitExitFullscreen', 'mozCancelFullScreen', 'msExitFullscreen']
            if typeof document[attr] is 'function'
                document[attr]()
                break
        return null
)

toggleFullScreen = ->
    m.startComputation()
    signal = if isFullScreen() then Signals.fullscreen.cancelled else Signals.fullscreen.requested
    signal.dispatch()
    setTimeout((-> m.endComputation()), 0)

isFullScreen = ->
    document.fullscreenElement or document.webkitFullscreenElement or document.mozFullScreen or document.msFullscreenElement

LayoutModule =
    controller: (bodyCtrl) ->
        ->
            self = @
            @theme = m.prop('Light')
            @verticalNav = m.prop(false)
            @showOffScreen = m.prop(false)

            @closeOffScreen = ->
                self.showOffScreen(false)
                return true

            @setVerticalNav = (value) ->
                ->
                    self.verticalNav(value)

                    # trigger the window resize event so other parts of the page know to check for changes.
                    evt = document.createEvent('UIEvents')
                    evt.initUIEvent('resize', true, false, window, 0)
                    window.dispatchEvent(evt)

            @body = bodyCtrl()

            return @

    view: (body) ->
        (ctrl) ->
            asideClasses = [
                cfg.THEMES[ctrl.theme()]
                if ctrl.verticalNav() then 'nav-vertical' else null
                if ctrl.showOffScreen() then 'nav-off-screen' else null
            ].filter((c) -> c isnt null).join('.')

            [
                m('section.hbox.stretch', [
                    m(
                        'aside#nav.' + asideClasses
                        [
                            m(
                                'section.vbox'
                                # FIXME - default mode should be smaller and mouseover should expand it without resizing the content section
                                # onmouseover: ctrl.setVerticalNav(false)
                                # onmouseout: ctrl.setVerticalNav(true)
                                [
                                    m('header.nav-bar.bg-dark', [
                                        m('a.btn.btn-link.visible-xs', {onclick: m.toggle(ctrl.showOffScreen)}, [Icon('bars')])
                                        m('a.nav-brand', ['Puff'])
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
                                        m('a.btn.btn-link', {onclick: toggleFullScreen}, [Icon('expand')])
                                        m('a.btn.btn-link.pull-right', {href: cfg.pages.login}, [Icon('power-off')])
                                    ])
                                ]
                            )
                        ]
                    )
                    m('main#content', body(ctrl.body))
                ])
            ]


document.addEventListener(
    'DOMContentLoaded'
    ->
        m.route.mode = 'hash'

        m.route(
            document.body
            ""
            {
                "": m.mixinLayout(LayoutModule, GalleryModule)
                "gallery": m.mixinLayout(LayoutModule, GalleryModule)
                "laverna": m.mixinLayout(LayoutModule, NotesModule)
            }
        )
)
