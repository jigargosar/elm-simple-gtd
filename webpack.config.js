const webpack = require('webpack');
const path = require("path");
const ServiceWorkerWebpackPlugin = require('serviceworker-webpack-plugin');
const pkg=require("./package.json");

const nodeENV = process.env.NODE_ENV || "development"

const isDevEnv = nodeENV === "development"

console.log("isDevEnv: ", isDevEnv, nodeENV)
console.log("process.env.NODE_ENV: ", isDevEnv, nodeENV)

const outputDir = isDevEnv ? "dev" : "app"


module.exports = {
    resolve: {
        alias: {elm: path.resolve(__dirname, 'src/elm/')}
    },
    // devtool: isDevEnv ? "inline" : 'source-map',
    devtool: isDevEnv? "eval": "source-map",
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
        new webpack.DefinePlugin({
            'IS_DEVELOPMENT_ENV': isDevEnv,
            'WEB_PACK_DEV_SERVER': process.env.WEB_PACK_DEV_SERVER || false,
            "packageJSON": JSON.stringify(pkg)
        }),
        new ServiceWorkerWebpackPlugin({
            options: {"foo": "bar"},
            entry: './src/web/notification-sw.js',
            filename: "notification-sw.js",
            template: function () {
                return Promise.resolve("var url = \"" + (
                        process.env.WEB_PACK_DEV_SERVER
                            ? "http://localhost:8020/" : "https://simplegtd.com/"
                    ) + "\";\n");
            }
        }),
        // new webpack.ProvidePlugin({
        //     firebase:"firebase"
        // }),
        // new HtmlWebpackPlugin({ title: 'Example', template: './index.html' }),
        // new webpack.LoaderOptionsPlugin({ options: { postcss: [ autoprefixer ] } })
        // new WriteFilePlugin(),
        new webpack.optimize.CommonsChunkPlugin({
            name: "common",
            minChunks: 2
        })
    ],

    module: {
        rules: [
            {
                test: /\.js$/,
                exclude: /(node_modules|bower_components)/,
                use: 'babel-loader',
            },
            {
                test: /\.elm$/,
                exclude: [/elm-stuff/, /node_modules/],
                // use: ["elm-hot-loader","elm-webpack-loader?verbose=true&debug=true"],
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
