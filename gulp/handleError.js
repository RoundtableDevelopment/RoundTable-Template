var gutil = require('gulp-util');

module.exports = function(err) {
  gutil.beep();
  console.log(err.toString());
  this.emit("end");
};