var gulp = require('gulp');

gulp.task('watch', ['setWatch', 'browserSync'], function() {
	gulp.watch('app/stylus/**', ['stylus']);
	gulp.watch('app/images/**', ['images']);
	gulp.watch('app/*.html', ['copy']);
    gulp.watch('app/**/*.{js,coffee}', ['webpack']);
});
