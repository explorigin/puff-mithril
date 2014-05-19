
m.factory(
    "application.config"
    () ->
        iconset: 'fontawesome'
        pages:
            home: 'home.html'
            login: 'index.html'
        oldLinks: [
                href: '/notes/'
                text: 'Notes'
        ]
)
