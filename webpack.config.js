const webpack = require('webpack');
const path = require("path");

const nodeENV = process.env.NODE_ENV || "development"

const isDevEnv = nodeENV === "development"

console.log("debug:", isDevEnv, nodeENV)


const outputDir = isDevEnv ? "dev" : "build"


module.exports = {
    resolve:{
        alias:{elm:path.resolve(__dirname, 'src/elm/')}
    },
    devtool: isDevEnv ? "inline" : 'source-map',
    // devtool: "source-map",
    // devtool: 'source-map', // not much useful for elm, and slows down dev-server
    entry: {
        common:["babel-polyfill",
        ],
        main: [
            './src/web/main.js',
        ]
    },

    output: {
        path: path.resolve(__dirname + "/" + outputDir),
        filename: '[name]-bundle.js',
    },

    plugins: [
        new webpack.DefinePlugin({
            'NODE_ENV': JSON.stringify(nodeENV),
            'WEB_PACK_DEV_SERVER': process.env.WEB_PACK_DEV_SERVER || false
        }),
        // new webpack.ProvidePlugin({
        //     firebase:"firebase"
        // }),
        // new webpack.optimize.CommonsChunkPlugin({
        //     name: "vendor",
        //     filename: "vendor.js",
        //     chunks: ["options"]
        // })
        // new HtmlWebpackPlugin({ title: 'Example', template: './index.html' }),
        // new webpack.LoaderOptionsPlugin({ options: { postcss: [ autoprefixer ] } })
        // new WriteFilePlugin(),
        // new webpack.optimize.CommonsChunkPlugin({
        //     name: 'inline',
        //     filename: 'inline.js',
        //     minChunks: Infinity
        // }),
        // new webpack.optimize.AggressiveSplittingPlugin({
        //     minSize: 5000,
        //     maxSize: 10000
        // })
        new webpack.optimize.CommonsChunkPlugin({
            name:"common",
            minChunks:2
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
                // use: ["elm-hot-loader","elm-webpack-loader?debug=true"],
                use: ["elm-hot-loader","elm-webpack-loader"],
            },
            {
                test: /\.(pcss|css)$/,
                loader: 'style-loader!css-loader?importLoaders=1!postcss-loader'
            },
            {
                test: /\.(html|json)$/,
                // exclude: /node_modules|components/,
                use: 'file-loader?name=[name].[ext]',
                // use: 'file-loader',
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
        contentBase:"./src/web/"
    },

};
