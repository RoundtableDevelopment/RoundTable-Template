var htmlDir           = './app/views';
var assetDir          = './gulp/assets';
var outputDir         = './lib/assets';
var scriptsDir        = '/scripts';
var nodeDir           = './node_modules';
var scriptBundleName  = '/bundle.js';

module.exports = {
    sass: {
      src: assetDir + '/stylesheets/style.scss',
      watch: assetDir + '/stylesheets/**/*',
      dest: outputDir + '/stylesheets',
      includes: []
    },

    scripts: {
      src: [
        assetDir + scriptsDir + '/index.js',
      ],
      clean: assetDir + scriptsDir + scriptBundleName,
      watch: assetDir + scriptsDir + '/**/*',
      dest: outputDir + '/scripts'
    },

    html: {
      watch: htmlDir + '/**/*',
    }
}