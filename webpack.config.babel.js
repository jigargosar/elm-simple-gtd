import webpack from "webpack"
import path from "path"
import ServiceWorkerWebpackPlugin from "serviceworker-webpack-plugin"
import _ from "ramda"
// import HtmlWebpackPlugin from "html-webpack-plugin"
// import ExtractTextPlugin from "extract-text-webpack-plugin"
import SWPrecacheWebpackPlugin from "sw-precache-webpack-plugin"

// idea setting: /Users/jigargosar/GitHub/elm-simple-gtd/webpack.config.babel.js
//todo: refactor https://github.com/simonh1000/elm-webpack-starter/blob/master/webpack.config.js

const nodeENV = process.env.NODE_ENV
const isWebPackDevServer = process.env.WEBPACK_DEV_SERVER === "true"


console.log(`webpack: process.env.NODE_ENV: "${nodeENV}"`)

const envList = ["development", "production"]
if (!_.contains(nodeENV)(envList)) {
  console.error("webpack: Error process.env.NODE_ENV invalid", nodeENV)
  process.exit(1)
}

const isDevEnv = nodeENV === "development"
console.log("webpack: isDevEnv: ", isDevEnv)
console.log("webpack: isWebPackDevServer: ", isWebPackDevServer)


const envOutputDir = isDevEnv ? "dev" : "prod"

const outputPath = path.resolve(__dirname, "build", envOutputDir)


const commonPlugins = [
  // new ExtractTextPlugin(styleFileName),
  // Suggested for hot-loading
  new webpack.NamedModulesPlugin(),
  // Prevents compilation errors causing the hot loader to lose state
  new webpack.NoEmitOnErrorsPlugin(),
  
  new webpack["ProvidePlugin"]({
    jQuery: "jquery",
    "window.jQuery": "jquery",
  }),
  new webpack.DefinePlugin({
    'NODE_ENV': JSON.stringify(process.env.NODE_ENV),
    "process.env": JSON.stringify(process.env),
    "WEBPACK_DEV_SERVER": isWebPackDevServer,
  }),
  new ServiceWorkerWebpackPlugin({
    entry: './notification-sw.js',
    filename: "notification-sw.js",
    transformOptions(_) {
      return {isDevEnv: isWebPackDevServer}
    },
  }),
  new webpack.optimize.CommonsChunkPlugin({
    name: "common",
    minChunks: 2,
  }),
]
const excludeInDevServerModePlugins = [
  new SWPrecacheWebpackPlugin({
    cacheId: 'simple-gtd',
    filename: 'service-worker.js',
    importScripts: ["notification-sw.js"],
    staticFileGlobs: [
      'static/**',
    ],
    stripPrefix: "static/",
    mergeStaticsConfig: true,
    minify: !isWebPackDevServer,
    maximumFileSizeToCacheInBytes: 5242880, // 5mb
  }),
]
const plugins = _.concat(commonPlugins, isWebPackDevServer ? [] : excludeInDevServerModePlugins)

const disableLanding = true
const extraEntry = isWebPackDevServer && disableLanding ? {} : {"landing": ["./landing.js"],}

export default {
  resolve: {
    alias: {
      elm: path.resolve(__dirname, 'src/elm/'),
    },
  },
  context: path.resolve(__dirname, "src/web/"),
  entry: _.merge({
    "common": [
      "babel-polyfill",
      "materialize-css/dist/js/materialize",
      "./scss/main.scss",
      "./pcss/main.pcss",
      "./font-loader",
      "./analytics.js",
      "./index.html",
      "./app.html",
    ],
    "app": ["./app.js"],
  }, extraEntry),
  
  output: {
    path: outputPath,
    filename: '[name].bundle.js',
  },
  
  plugins: plugins,
  
  module: {
    rules: [
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: [
          "elm-hot-loader",
          {
            loader: "elm-webpack-loader",
            options: {
              // pathToMake:"./elm-make.sh",
              verbose: true,
              warn: false,
              debug: false,
              cwd: path.resolve(__dirname),
            },
          },
        ],
        // loader: 'elm-hot-loader!elm-webpack-loader?verbose=true&warn=false',
      },
      {
        test: /\.js$/,
        exclude: function (fileName) {
          return !_.test(/crypto-random-string/, fileName)
                 && _.test(/(node_modules|bower_components)/, fileName)
        },
        use: 'babel-loader',
      },
      {
        test: /\.(pcss|css)$/,
        
        use: [
          'style-loader',
          {loader: 'css-loader', options: {importLoaders: 1}},
          'postcss-loader',
        ],
      },
      {
        test: /\.scss$/,
        use: [
          {loader: "style-loader"},
          {loader: "css-loader"},
          {loader: "sass-loader"},
        ],
      },
      {
        test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        use: [
          {
            loader: 'url-loader',
            options: {
              name: "[path][name].[ext]",
              // useRelativePath: isWebPackDevServer,
              limit: 10000,
              mimetype: "application/font-woff",
            },
          },
        ],
      },
      
      {
        test: /\.(ttf|eot|svg|png)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        use: 'file-loader',
      },
      {
        test: /\.(html)$/,
        use: [
          {
            loader: 'file-loader',
            options: {
              name: "[path][name].[ext]",
            },
          },
        ],
      },
    ],
    
    // noParse: [/\.elm$/],
    
  },
  
  devServer: {
    // stats: {colors: false, "errors-only":true},
    stats: {modules: false, assets: false},
    // stats: "errors-only",
    // stats: "minimal",
    port: 8020,
    overlay: true,
    watchContentBase: true,
    // open:true,
    // hot:true,
    // inline: true,
    contentBase: [path.join(__dirname, "static")],
    host: "localhost",
    watchOptions: {
      aggregateTimeout: 700,
    },
  },
};
