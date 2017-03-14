module.exports = {
    plugins: [
        require("postcss-import")({ addDependencyTo: require("webpack") }),
        require("postcss-url")(),
        require("postcss-cssnext")(),
        // add your "plugins" here
        // ...
        // and if you want to compress,
        // just use css-loader option that already use cssnano under the hood
        require("postcss-browser-reporter")(),
        require("postcss-reporter")(),
    ]

}