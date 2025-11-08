const path = require('path');

module.exports = {
  target: 'electron-main',
  entry: {
    main: './src/main/main.ts',
    preload: './src/main/preload.ts'
  },
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[name].js'
  },
  resolve: {
    extensions: ['.ts', '.js'],
    alias: {
      '@': path.resolve(__dirname, 'src'),
      '@main': path.resolve(__dirname, 'src/main'),
      '@shared': path.resolve(__dirname, 'src/shared')
    }
  },
  module: {
    rules: [
      {
        test: /\.ts$/,
        use: {
          loader: 'ts-loader',
          options: { transpileOnly: true }
        },
        exclude: /node_modules/
      }
    ]
  },
  node: {
    __dirname: false,
    __filename: false
  },
  externals: {
    'electron': 'commonjs electron',
    'diff': 'commonjs diff',
    'chardet': 'commonjs chardet',
    'iconv-lite': 'commonjs iconv-lite'
  }
};