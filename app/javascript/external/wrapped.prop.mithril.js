// https://gist.github.com/explorigin/0b802208b916055ba918
//
// Usage:
// var ComputedProp = m.wrappedProp(m.startComputation, m.endComputation),
//     progress = ComputedProp(0);
//
// When progress is changed outside of a normal event handler, it will still update the UI.

(function (m) {
    m.wrappedProp = function(propWillUpdate, propUpdated) {
        return function(store) {
            var prop = function() {
                var a = arguments[0]
                if (arguments.length) {
                    propWillUpdate(store, a)
                    store = a
                    propUpdated(store, a)
                }
                return store
            }
            prop.toJSON = function() {
                return store
            }
            return prop
        }
    }
})(Mithril);
