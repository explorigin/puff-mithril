(function(m) {
    // Choose among a dictionary of options.
    // key - the key to select from options
    // options - a map of [view_func, controller]
    m.choose = function(key, options) {
        var option = options[key];
        return option[0](option[1]);
    };

    m.toggle = function(prop) {
        return function(evt) { prop(!prop()); };
    };

    m.cachedComputed = function(compute, deferEvaluation) {
        var store = undefined,
            d = null,
            prop = function() { return store; };

        function storeAnswer(value) {
            if (typeof value.then === 'function') {
                return value.then(storeAnswer)
            } else {
                deferred = d
                d = null;
                store = value;
                deferred.resolve(store);
                return value;
            }
        }

        prop.clear = function() {
            store = undefined;
            if (d !== null) {
                d.reject(new Error('Property cleared'));
                d = null;
            }
        };
        prop.refresh = function() {
            if (d !== null) {
                return d.promise;
            } else {
                d = m.deferred();
                setTimeout(function () {
                    try {
                        var result = compute.apply(self, this.args);
                        return storeAnswer(result);
                    } catch (e) {
                        deferred = d
                        d = null;
                        deferred.reject(e);
                    }
                }.bind({args: Array.prototype.slice.call(arguments, 0)}), 0);
                return d.promise;
            }
        };
        prop.toJSON = function() {
            return store
        };

        if (!deferEvaluation) {
            prop.refresh();
        }

        return prop
    };

    m.debubble = function(evtHandler) {
        return function(evt) {
            evt.stopPropagation();
            evt.preventDefault();
            m.startComputation();
            try { return evtHandler.apply(this, arguments); }
            finally { m.endComputation(); }
        };
    };
})(Mithril);
