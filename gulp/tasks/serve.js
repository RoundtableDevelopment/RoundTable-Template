var gulp        = require('gulp');
var gutil       = require('gulp-util');
var browserSync = require('browser-sync').create();
var reload      = browserSync.reload;
var config      = require('../config');

gulp.task('serve', function() {
  browserSync.init({
      proxy: 'localhost:3000',
  });

  gutil.log(gutil.colors.magenta('Watching source files...'));
  gulp.watch(config.sass.watch, ['sass', reload]);
  gulp.watch(config.scripts.watch, ['scripts', reload]);
  gulp.watch(config.html.watch, ['',reload]);
});