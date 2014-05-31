// https://gist.github.com/ilsenem/11345055

(function (m) {
    var repository = {};

    m.factory = function (name, dependencies, func) {
        if (typeof repository[name] !== "undefined") {
            throw new Error("Duplicate dependency entry");
        } else if (typeof dependencies === "undefined") {
            throw new Error("Empty dependency list");
        }

        repository[name] = {
            fn : typeof dependencies === "function" ? dependencies : func || null,
            dependencies : Array.isArray(dependencies) ? dependencies || null : null,
            instance : null
        };

        if (repository[name].fn === null) {
            throw new Error("Empty repository entry");
        } else if (typeof repository[name].fn !== "function") {
            throw new Error("Dependency not a function");
        }
    };

    m.handle = function (name, params, scope) {
        var resolved;

        if (typeof repository[name] === "undefined") {
            throw new Error("Undefined dependency resolve: " + name);
        }

        if (repository[name].instance === null) {
            resolved = [];

            if (repository[name].dependencies !== null) {
                repository[name].dependencies.forEach(function(dependency) {
                    return resolved.push(m.handle(dependency));
                });
            }

            repository[name].instance = repository[name].fn.apply(scope || {}, resolved.concat(Array.prototype.slice.call(params || [], 0)));
        }

        return repository[name].instance;
    };
})(Mithril);
