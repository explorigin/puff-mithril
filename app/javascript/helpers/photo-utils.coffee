# helpers/photo-utils.js
m = require('mithril')

scrollBarWidth = null
getScrollBarWidth = ()->
    return scrollBarWidth unless scrollBarWidth is null

    inner = document.createElement('p')
    inner.style.width = "100%"
    inner.style.height = "200px"

    outer = document.createElement('div')
    outer.style.position = "absolute"
    outer.style.top = "0px"
    outer.style.left = "0px"
    outer.style.visibility = "hidden"
    outer.style.width = "200px"
    outer.style.height = "150px"
    outer.style.overflow = "hidden"
    outer.appendChild(inner)

    document.body.appendChild (outer)
    w1 = inner.offsetWidth
    outer.style.overflow = 'scroll'
    w2 = inner.offsetWidth
    if w1 == w2
        w2 = outer.clientWidth

    document.body.removeChild(outer)

    scrollBarWidth = w1 - w2
    return scrollBarWidth

module.exports =
    resize: (img, max_width, max_height, mimetype='image/jpeg', quality=0.7) ->
        c = document.createElement('canvas')
        context = c.getContext('2d')

        width = img.width
        height = img.height

        if width > height
            if width > max_width
                height *= max_width / width
                width = max_width

        else
            if height > max_height
                width *= max_height / height
                height = max_height

        c.width = width
        c.height = height
        context.drawImage(img, 0, 0, width, height)

        resized_img = new Image(width, height)
        resized_img.src = c.toDataURL(mimetype, quality)
        return resized_img

    scrollBarWidth: getScrollBarWidth

