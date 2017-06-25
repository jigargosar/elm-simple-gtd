import webpack from "webpack"
import path from "path"
import ServiceWorkerWebpackPlugin from "serviceworker-webpack-plugin"
import _ from "ramda"
import HtmlWebpackPlugin from "html-webpack-plugin"
import ExtractTextPlugin from "extract-text-webpack-plugin"

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


const envOutputDir = isDevEnv ? "dev" : "app"

const outputPath = path.resolve(__dirname , envOutputDir)
const styleFileName = isWebPackDevServer ? "style.css": '/assets/css/style.css'
export default {
    resolve: {
        alias: {elm: path.resolve(__dirname, 'src/elm/')}
    },
    // devtool: isDevEnv ? "inline" : 'source-map',
    // devtool: isDevEnv? "": "source-map",
    // devtool: 'source-map', // not much useful for elm, and slows down dev-server
    entry: {
        // "vendor":["./src/web/vendor.js"],
        "app": ["./src/web/app.js"],
        "landing": ["./src/web/landing.js"],
    },

    output: {
        path: outputPath,
        filename: '[name].js',
    },

    plugins: [
        // new ExtractTextPlugin(styleFileName),
        new webpack["ProvidePlugin"]({
            $: "jquery",
            jQuery: "jquery",
            "window.jQuery": "jquery"
        }),
        new webpack.DefinePlugin({
            'IS_DEVELOPMENT_ENV': isDevEnv,
            "process.env": JSON.stringify(process.env)
        }),
        new ServiceWorkerWebpackPlugin({
            entry: './src/web/notification-sw.js',
            filename: "notification-sw.js",
            template: function () {
                return Promise.resolve(serviceWorkerTemplate)
            }
        }),
        new webpack.optimize.CommonsChunkPlugin({
            name: "common",
            minChunks: 2
        })
    ],

    module: {
        rules: [
            {
                test: /\.js$/,
                exclude: function (fileName) {
                    return !_.test(/crypto-random-string/, fileName)
                           && _.test(/(node_modules|bower_components)/, fileName)
                },
                use: 'babel-loader',
            },
            {
                test: /\.elm$/,
                exclude: [/elm-stuff/, /node_modules/],
                // use: ["elm-hot-loader","elm-webpack-loader?verbose=true&warn=true"],
                use: ["elm-hot-loader", "elm-webpack-loader?verbose=true"],
                // use: ["elm-hot-loader","elm-webpack-loader?debug=true"],
                // use: ["elm-hot-loader", "elm-webpack-loader"],
            },
            /*{
                test: /\.scss$/,
                use: ExtractTextPlugin.extract({
                    fallback: 'style-loader',
                    use: [
                        "css-loader",
                        "sass-loader",
                    ],
                })
            },
            {
                test: /\.(pcss|css)$/,

                use: ExtractTextPlugin.extract({
                    fallback: 'style-loader',
                    use: [
                        'css-loader',
                        'postcss-loader',
                    ],
                })
            },*/
            {
                test: /\.(pcss|css)$/,

                use: [
                    'style-loader',
                    {loader: 'css-loader', options: {importLoaders: 1}},
                    'postcss-loader'
                ]
            },
            {
                test: /\.scss$/,
                use: [
                    {loader: "style-loader"},
                    {loader: "css-loader"},
                    {loader: "sass-loader"}
                ]
            },
            {
                test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                use:[{
                    loader: 'url-loader',
                    query: {
                        name:"[name].[ext]",
                        outputPath:"/assets/fonts/",
                        //todo: change this value based on dev server mode.
                        useRelativePath: isWebPackDevServer,
                        "limit": 50000,
                        "mimetype": "application/font-woff",
                    }}]
            },
            {
                test: /\.(ttf|eot|svg|png)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                use: 'file-loader',
            },
        ],

        noParse: [/\.elm$/],

    },

    devServer: {
        // stats: {colors: false, "errors-only":true},
        stats: "minimal",
        port: 8020,
        overlay: true,
        watchContentBase: true,
        // open:true,
        // inline: false,
        contentBase: ["src/web/", "static/",],
        host: "0.0.0.0",

    },



    // performance: {
    //     hints: "warning"
    // },

};


const serviceWorkerTemplate =
    `
        const isDevEnv = ${isDevEnv};
    
    `
