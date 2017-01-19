var gulp = require('gulp'),
	coffee = require('gulp-coffee')
	ts = require('gulp-typescript')
	jasmineNode = require('gulp-jasmine-node');

gulp.task('default', function() {
	gulp.src('./coffee/**/*.coffee')
		.pipe(coffee({bare: false}))
		.pipe(gulp.dest('./built/'));

	gulp.src('typescript/**/*.ts')
		.pipe(
			ts({
				"module": "commonjs",
				"target": "es5",
				"noImplicitAny": false,
				"sourceMap": false
			})
		)
		.pipe( gulp.dest('./built/') );
		//.pipe( jasmineNode({ timeout: 10000 }) );
});

gulp.task('watch', function() {
	gulp.watch('./coffee/**/*', ['default']);
});
