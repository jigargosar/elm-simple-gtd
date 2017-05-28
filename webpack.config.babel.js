import webpack from "webpack"
import path from "path"
import ServiceWorkerWebpackPlugin from "serviceworker-webpack-plugin"
import _ from "ramda"

const nodeENV = process.env.NODE_ENV
console.log(`webpack: process.env.NODE_ENV: "${nodeENV}"`)

const envList = ["development", "production"]
if (!_.contains(nodeENV)(envList)) {
    console.error("webpack: Error process.env.NODE_ENV invalid", nodeENV)
    process.exit(1)
}

const isDevEnv = nodeENV === "development"
console.log("webpack: isDevEnv: ", isDevEnv)


const outputDir = isDevEnv ? "dev" : "app"

export default {
    resolve: {
        alias: {elm: path.resolve(__dirname, 'src/elm/')}
    },
    // devtool: isDevEnv ? "inline" : 'source-map',
    // devtool: isDevEnv? "": "source-map",
    // devtool: 'source-map', // not much useful for elm, and slows down dev-server
    entry: {
        common: "./src/web/common-require.js",
        main: "./src/web/main.js"
    },

    output: {
        path: path.resolve(__dirname + "/" + outputDir),
        filename: '[name].js',
    },

    plugins: [
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
            {
                test: /\.(pcss|css)$/,
                loader: 'style-loader!css-loader?importLoaders=1!postcss-loader'
            },
            {
                test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                use: 'url-loader?limit=10000&mimetype=application/font-woff',
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
        // open:true,
        // inline: false,
        contentBase: ["src/web/", "static/",],
        host: "0.0.0.0",
    },

};


const serviceWorkerTemplate =
    `
        const isDevEnv = ${isDevEnv};
    
    `
