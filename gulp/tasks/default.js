var gulp          = require('gulp');
var gulpSequence  = require('gulp-sequence');

gulp.task('default', function(cb) {
  gulpSequence('clean:all', 'build', 'serve', cb);
});