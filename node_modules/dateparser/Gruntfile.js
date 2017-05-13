module.exports = function(grunt) {
	grunt.initConfig({
		pkg: grunt.file.readJSON('package.json'),
		browserify: {
			dist: {
				options: {
					banner: '/*! <%= pkg.name %>@<%= pkg.version %> by <%= pkg.author %> Copyright (c) <%= grunt.template.today("yyyy")%>. Licensed under the Apache-2.0 */\n',
					transform: ['debowerify', 'decomponentify', 'deamdify', 'deglobalify']
				},
				files: {
					'dist/dateparser.min.js' : ['index.js']
				}
			}
		},
		uglify: {
			dist: {
				options: {
					preserveComments: 'some'
				},
				files: {
					'dateparser.min.js': 'dist/dateparser.min.js'
				}
			}
		},
		mochaTest: {
			test: {
				options: {
					reporter: 'spec'
				},
				src: ['test/**/*.js']
			}
		}
	});

	grunt.loadNpmTasks('grunt-mocha-test');
	grunt.loadNpmTasks('grunt-browserify');
	grunt.loadNpmTasks('grunt-contrib-uglify');

	grunt.registerTask('test', ['mochaTest']);
	grunt.registerTask('default', ['mochaTest', 'browserify', 'uglify']);
};
