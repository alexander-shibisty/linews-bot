var gulp = require('gulp'),
	coffee = require('gulp-coffee');

gulp.task('coffee', function() {
	gulp.src('./coffee/**/*.coffee')
		.pipe(coffee({bare: false}))
		.pipe(gulp.dest('./'));
});

gulp.task('watch', function() {
	gulp.watch('./coffee/**/*', ['coffee']);
});
