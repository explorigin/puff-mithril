var gulp = require('gulp'),
    htmlreplace = require('gulp-html-replace'),
    manifest = require('gulp-manifest'),

    coffee = require('gulp-coffee'),
    stylus = require('gulp-stylus'),
    concat = require('gulp-concat'),
    assets = require('gulp-assets'),
    htmlmin = require('gulp-htmlmin'),
    uglify = require('gulp-uglify'),
    csso = require('gulp-csso'),

    paths = {
        distHtml: ['build/*.html'],
        distImages: ['build/**/*.{gif,jpg,png}'],
        coffee: ['app/**/*.coffee'],
        copyables: ['app/**/*.{html,js,woff,map,gif,jpg,png,css}', '!app/**/*.min.{css,js}'],
        stylus: ['app/css/*.styl', '!app/bower_components/**/*.styl']
    };


gulp.task('stylus', function() {
    return gulp.src(paths.stylus)
        .pipe(stylus({errors: true}))
        .pipe(gulp.dest('build/css'));
});

gulp.task('coffeescript', function() {
    return gulp.src(paths.coffee)
        .pipe(coffee({bare: true}))
        .pipe(gulp.dest('build'));
});

gulp.task('copyables', function() {
    return gulp.src(paths.copyables).pipe(gulp.dest('build'));
});

gulp.task('scripts', ['coffeescript', 'copyables']);
gulp.task('styles', ['stylus', 'copyables']);


// Concat and minify for distribution
gulp.task('dist-styles', ['copyables'], function() {
    return gulp.src(paths.distHtml)
        .pipe(assets({js: false, css: true}))
        .pipe(concat('all.css'))
        .pipe(csso())
        .pipe(gulp.dest('dist'));
});

gulp.task('dist-scripts', ['copyables'], function() {
    return gulp.src(paths.distHtml)
        .pipe(assets({js: true, css: false}))
        .pipe(concat('all.js'))
        .pipe(uglify())
        .pipe(gulp.dest('dist'));
});

gulp.task('dist-images', ['copyables'], function() {
    return gulp.src(paths.distImages).pipe(gulp.dest('dist'));
});

gulp.task('dist-html', ['copyables'], function() {
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

    gulp.watch([paths.coffee], ['scripts'])
        .on('change', logIt);
    gulp.watch([paths.copyables], ['copyables'])
        .on('change', logIt);
    gulp.watch(['app/**/*.styl'], ['styles'])
        .on('change', logIt);
});

gulp.task('build', ['styles', 'scripts', 'copyables']);
gulp.task('dist', [
    'build',
    'dist-scripts',
    'dist-styles',
    'dist-images',
    'dist-html',
    'manifest']);

gulp.task('default', ['dist']);
