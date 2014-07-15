
m.factory(
    "application.signals"
    () ->
        Signal = signals.Signal

        fullscreen:
            requested: new Signal()
            cancelled: new Signal()
)
