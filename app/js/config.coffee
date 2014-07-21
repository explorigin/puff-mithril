
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
        applications: [
            {
                name: 'Files'
                icon: 'file'
                query: ''
                module: 'files'
            }, {
                name: 'Notes'
                icon: 'check'
                query: null
                module: 'laverna'
            }, {
                name: 'Gallery'
                icon: 'picture-o'
                query: null
                module: 'gallery'
            # }, {
            #     name: 'Invoice'
            #     icon: 'book'
            #     query: null
            #     module: 'invoice'
            # }, {
            #     name: 'Messages'
            #     icon: 'envelope-o'
            #     query: null
            #     module: 'messages'
            }
        ]
        THEMES:
            'Light': 'bg-light'
            'Dark': 'bg-dark'
            'Night': 'bg-black'
            'Barney': 'bg-primary'
)
