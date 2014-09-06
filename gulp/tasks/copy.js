var gulp = require('gulp'),
    htmlmin = require('gulp-htmlmin');

gulp.task('copy', ['styles'], function() {
    var stream = gulp.src('app/*.html')

    if (!global.isWatching) {
        stream = stream.pipe(htmlmin({collapseWhitespace: true}));
    }

    stream.pipe(gulp.dest('dist'));

    return gulp.src('app/*.{xml,md,txt}').pipe(gulp.dest('dist'));
});


var assets = [
    'app/bower_components/animate.css/animate.css',
    'app/bower_components/bootstrap/dist/**',
    'app/bower_components/pouchdb/dist/pouchdb.min.js',
    'app/bower_components/font-awesome/**'
];

gulp.task('styles', function() {
    return gulp.src(assets)
               .pipe(gulp.dest('./dist/vendor/'));
});
