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

const outputPath = path.resolve(__dirname, envOutputDir)
const styleFileName = isWebPackDevServer ? "style.css" : '/assets/css/style.css'

export default {
    resolve: {
        alias: {
            elm: path.resolve(__dirname, 'src/elm/'),
            bower_components: path.resolve(__dirname, 'bower_components/')
        }
    },
    context: path.resolve(__dirname, "src/web/"),
    entry: {
        "common": [
            "babel-polyfill",
            "bower_components/webcomponentsjs/webcomponents-loader",
            "materialize-css/dist/js/materialize.min",
            "./scss/main.scss",
            "./pcss/main.pcss",
        ],
        "app": ["./app.js"],
        "landing": ["./landing.js"],
    },

    output: {
        path: outputPath,
        filename: '[name].bundle.js',
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
            entry: './notification-sw.js',
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
                test: /\.elm$/,
                exclude: [/elm-stuff/, /node_modules/],
                use: [
                    "elm-hot-loader",
                    {
                        loader: "elm-webpack-loader",
                        options: {
                            verbose: true,
                            warn: false,
                            debug: false,
                        },
                    }
                ],
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
                use: [
                    {
                        loader: 'url-loader',
                        options: {
                            name: "[name].[ext]",
                            outputPath: "/assets/fonts/",
                            useRelativePath: false,
                            limit: 10000,
                            mimetype: "application/font-woff",
                        }
                    }
                ]
            },
            {
                test: /\.(ttf|eot|svg|png)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                use: 'file-loader',
            },
        ],

        // noParse: [/\.elm$/],

    },

    devServer: {
        // stats: {colors: false, "errors-only":true},
        stats: "minimal",
        port: 8020,
        overlay: true,
        watchContentBase: true,
        open:true,
        inline: false,
        contentBase: ["static/",],
        host: "localhost",
    },
};


const serviceWorkerTemplate =
    `
        const isDevEnv = ${isDevEnv};
    
    `
