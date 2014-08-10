var stylus      = require('gulp-stylus'),
    gulp         = require('gulp'),
    handleErrors = require('../util/handleErrors'),
    csso       = require('gulp-csso');

gulp.task('stylus', function() {
    var stream = gulp.src('./app/stylus/*.styl')
        .pipe(stylus({errors: true}));

    if (!global.isWatching) {
        stream = stream.pipe(csso());
    }

    return stream.pipe(gulp.dest('./dist/'))
                 .on('error', handleErrors);
});
