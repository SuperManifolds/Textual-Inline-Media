module.exports = {
  context: __dirname,
  entry: './Textual Inline Media/Resources/gen/InlineMedia.js',
  output: {
    path: __dirname + '/Textual Inline Media/Resources',
    filename: 'InlineMedia.js',
    library: 'InlineMedia',
    libraryTarget: 'var'
  }
};
