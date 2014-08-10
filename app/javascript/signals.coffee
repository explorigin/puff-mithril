require('mithril')
Signal = require('js-signals/dist/signals').Signal

m.factory(
    "application.signals"
    () ->
        fullscreen:
            requested: new Signal()
            cancelled: new Signal()
)
