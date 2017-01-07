var gulp          = require('gulp');
var sass          = require('gulp-sass') ;
var minifyCss     = require('gulp-cssnano');
var gutil         = require('gulp-util');
var autoprefixer  = require('gulp-autoprefixer');
var plumber       = require('gulp-plumber');
var config        = require('../config').sass;
var handleError   = require('../handleError');


gulp.task('sass', ['clean:sass'], function() {
  return gulp
    .src(config.src)
    .pipe(plumber({
      errorHandler: handleError
    }))
    .pipe(sass({
      style: "compressed",
      includePaths: config.includes
    }))
    .pipe(autoprefixer())
    .pipe(gutil.env.type === 'production' ? minifyCss() : gutil.noop())
    .pipe(gulp.dest(config.dest));
});