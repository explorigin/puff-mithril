var gulp = require('gulp'),
    htmlreplace = require('gulp-html-replace'),
    manifest = require('gulp-manifest'),

    coffee = require('gulp-coffee'),
    stylus = require('gulp-stylus'),
    concat = require('gulp-concat'),
    msx = require('gulp-msx'),
    assets = require('gulp-assets'),
    htmlmin = require('gulp-htmlmin'),
    uglify = require('gulp-uglify'),
    csso = require('gulp-csso'),

    paths = {
        html: ['app/**/*.html'],
        distHtml: ['build/*.html'],
        images: ['app/**/*.{gif,jpg,png}'],
        distImages: ['build/**/*.{gif,jpg,png}'],
        coffee: ['app/**/*.coffee'],
        javascript: ['app/**/*.js', '!app/**/*.min.js'],
        jsx: ['app/**/*.jsx'],
        msx: ['app/**/*.jsx'],
        stylus: ['app/**/*.styl', '!app/bower_components/**/*.styl'],
        css: ['app/**/*.css']
    };


gulp.task('css', function() {
    return gulp.src(paths.css).pipe(gulp.dest('build'));
});

gulp.task('stylus', function() {
    return gulp.src(paths.stylus)
        .pipe(stylus({errors: true}))
        .pipe(gulp.dest('build'));
});

gulp.task('javascript', function() {
    return gulp.src(paths.javascript).pipe(gulp.dest('build'));
});

gulp.task('jsx', function() {
    return gulp.src(paths.jsx)
               .pipe(msx())
               .pipe(gulp.dest('build'));
});

gulp.task('coffeescript', function() {
    return gulp.src(paths.coffee)
        .pipe(coffee({bare: true}))
        .pipe(msx())
        .pipe(gulp.dest('build'));
});

gulp.task('scripts', ['coffeescript', 'javascript', 'jsx']);
gulp.task('styles', ['stylus', 'css']);

gulp.task('html', function() {
    return gulp.src(paths.html).pipe(gulp.dest('build'));
});

gulp.task('images', function() {
    return gulp.src(paths.images).pipe(gulp.dest('build'));
});

// Concat and minify for distribution
gulp.task('dist-styles', ['styles'], function() {
    return gulp.src(paths.distHtml)
        .pipe(assets({js: false, css: true}))
        .pipe(concat('all.css'))
        .pipe(csso())
        .pipe(gulp.dest('dist'));
});

gulp.task('dist-scripts', ['scripts'], function() {
    return gulp.src(paths.distHtml)
        .pipe(assets({js: true, css: false}))
        .pipe(concat('all.js'))
        .pipe(uglify())
        .pipe(gulp.dest('dist'));
});

gulp.task('dist-images', ['images'], function() {
    return gulp.src(paths.distImages).pipe(gulp.dest('dist'));
});

gulp.task('dist-html', ['html'], function() {
    return gulp.src(paths.distHtml)
        .pipe(htmlreplace({
            js: 'all.js',
            css: 'all.css'
        }))
        .pipe(htmlmin({collapseWhitespace: true}))
        .pipe(gulp.dest('dist'));
});

gulp.task('manifest', ['dist-html', 'dist-styles', 'dist-scripts', 'dist-images'], function(){
    return gulp.src(['dist/*.html', 'dist/*.css', 'dist/*.js', 'dist/images/*'])
        .pipe(manifest({
            hash: true,
            preferOnline: true,
            network: ['https://*', '*'],
            filename: 'app.manifest',
            exclude: 'app.manifest'
        }))
        .pipe(gulp.dest('dist'));
});


// Intended commands
gulp.task('watch', ['build'], function() {
    var logIt = function(event) {
        console.log('File ' + event.path + ' was ' + event.type + ', running tasks...');
    };

    gulp.watch([paths.javascript, paths.coffee], ['scripts'])
        .on('change', logIt);
    gulp.watch([paths.stylus, paths.css], ['styles'])
        .on('change', logIt);
    gulp.watch([paths.html], ['html'])
        .on('change', logIt);
});

gulp.task('build', ['styles', 'scripts', 'images', 'html']);
gulp.task('dist', [
    'build',
    'dist-scripts',
    'dist-styles',
    'dist-images',
    'dist-html',
    'manifest']);

gulp.task('default', ['dist']);
