var gulp   = require('gulp'),
	gutil   = require('gulp-util'),
	webpack   = require('webpack'),
	config     = require('../../webpack.config.js'),
	handleErrors = require('../util/handleErrors');

if (global.isWatching) {
    config.debug = true;
    config.watch = true;
    // Exclude the UglifyJS plugin when developing.
    config.plugins.splice(1, 1);
}

gulp.task('webpack', function(done) {
    webpack(config, function(err, stats) {
        if(err) handleErrors(err);
        gutil.log("[webpack]", stats.toString({}));
        done();
    });
});
