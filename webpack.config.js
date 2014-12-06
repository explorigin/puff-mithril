var webpack = require('webpack');

require('coffee-loader');

module.exports = {
    context: __dirname + "/app",
    entry: {
        index: 'pages/index.coffee',
        home: 'pages/home.coffee'
    },
    output: {
        path: __dirname + "/dist",
        filename: "[name].bundle.js",
        sourceMapFilename: "[id].source.map"
    },
    module: {
        loaders: [
            { test: /\.css$/, loader: "style!css" },
            { test: /\.coffee$/, loader: "coffee-loader" }
        ],
        preLoaders: [
            {test: /\.js$/, loader: "source-map-loader"}
        ]
    },
    resolve: {
        modulesDirectories: ['bower_components', 'javascript'],
        alias: {
            mithril: 'helpers/utils'
        },
        extensions: ['', '.js', '.coffee']
    },
    externals: {
        m: 'mithril'
    },
    plugins: [
        new webpack.optimize.CommonsChunkPlugin('commons.bundle.js'),
//        new webpack.optimize.UglifyJsPlugin({})
    ],
    devtool: 'source-map'
}
