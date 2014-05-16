(->
    defer = m.deferred()
    timeoutHandler = null

    document.addEventListener(
        'DOMContentLoaded'
        () ->
            m.module(
                document.getElementById('content'),
                m.handle('pages.index', [defer.promise])
            )
    )

    cm = document.getElementById('cookieMonster')

    cm.addEventListener(
        'mouseover'
        () ->
            timeoutHandler = setTimeout(
                () ->
                    defer.resolve()
                3000
            )
    )

    cm.addEventListener(
        'mouseout'
        () ->
            clearTimeout(timeoutHandler)
    )
)()
