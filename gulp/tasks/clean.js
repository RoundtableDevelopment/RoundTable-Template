var gulp    = require('gulp');
var del     = require('del');
var config  = require('../config');

gulp.task('clean:all', function() {
  return del([
    config.sass.dest, 
    config.scripts.clean
  ]);
});

gulp.task('clean:sass', function() {
  return del([config.sass.dest]);
});

gulp.task('clean:scripts', function() {
  return del([config.scripts.clean]);
});
