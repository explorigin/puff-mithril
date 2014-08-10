// https://gist.github.com/explorigin/98bebb7b1e95e1688364
//
// Usage:
// var d = m.deferred()
// d.notify(currentValue/maxValue)
// return d
//
// In the calling method:
// promise.then(onsuccess, onerror, onprogress)

(function (m) {
    var none = {}, identity = function () {}
    m.deferred = function() {
        var resolvers = [], rejecters = [], progressers = [], resolved = none, rejected = none, promise = m.prop()
        var object = {
            resolve: function(value) {
                if (resolved === none) promise(resolved = value)
                for (var i = 0; i < resolvers.length; i++) resolvers[i](value)
                resolvers.length = rejecters.length = progressers.length = 0
            },
            reject: function(value) {
                if (rejected === none) rejected = value
                for (var i = 0; i < rejecters.length; i++) rejecters[i](value)
                resolvers.length = rejecters.length = progressers.length = 0
            },
            notify: function(value) {
                for (var i = 0; i < progressers.length; i++) progressers[i](value)
            },
            promise: promise
        }
        object.promise.resolvers = resolvers
        object.promise.then = function(success, error, progress) {
            var next = m.deferred()
            if (!success) success = identity
            if (!error) error = identity
            if (!progress) progress = identity
            function callback(method, callback) {
                return function(value) {
                    try {
                        var result = callback(value)
                        if (result && typeof result.then == "function") result.then(next[method], error)
                        else next[method](result !== undefined ? result : value)
                    }
                    catch (e) {
                        if (e instanceof Error && e.constructor !== Error) throw e
                        else next.reject(e)
                    }
                }
            }
            if (resolved !== none) callback("resolve", success)(resolved)
            else if (rejected !== none) callback("reject", error)(rejected)
            else {
                resolvers.push(callback("resolve", success))
                rejecters.push(callback("reject", error))
                progressers.push(callback("notify", progress))
            }
            return next.promise
        }
        return object
    }
})(Mithril);
