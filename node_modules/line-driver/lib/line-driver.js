/*****
Copyright 2015
Author	: Brian Ninni
Website	: ninni.io
Email	: brian@ninni.io
License	: MIT
=========================================
TODO:
http://www.2ality.com/2011/08/universal-modules.html
	
Don't use nested functions
	
Combine 'clean' and 'valid'
	-just let the 'valid' function modify the 'line'

Separate function to run before and after a range of lines is processed?
	(init and close are only run once, but before and after are run for each range?)
	
parser.previousLine and goToline( -1 )
	-also remember to update the index values

parser.isLastLine (boolean)
parser.linesRemaining (int)
	
Allow first, last, step, count to be changed dynamically
-or, allow them to be functions
	-also allow path, etc, to be functions? arrays?

Templates should be able to reference other templates

Error checking on invalid inputs

Write to http/https using POST?
*****/
var fs = require('fs'),
	http = require('http'),
	https = require('https'),
	url = require('url'),
	readFile = fs.readFile,
	readFileSync = fs.readFileSync,
	writeFile = fs.writeFile,
	writeFileSync = fs.writeFileSync,
	Settings = {
		maxRedirects : 5,
		encoding : 'utf8',
		delimiter : new RegExp('\r\n?|\r?\n'),
		join : '\n',
		eof : '',
		first : 1,
		step : 1,
		trim : false,
		commentDelim : '',
		ignoreEmpty : false,
		absolute : false,
		sync : false
	},
	Templates = {};
	
//To remove and return the first element of the given array
function getFirst( arr ){
	return arr.splice(0,1)[0];
}

//To add the given object as the first index of the given array
function addFirst( arr, obj ){
	arr.splice(0,0,obj);
}

//To see if the given value is a string or not
function isString( s ){
	return typeof s === 'string';
}
	
/*****
The main read lines function
line	:	the array of strings extract from the file
init	:	the function to run when lines begin to be read
clean	:	the function which takes a string and returns a cleaned version.  Might be used to remove comments or to trim surrounding whitespace
valid	:	the function to determine whether the string is valid enough to be sent through to the line.  Might be used to ignore empty lines or compiler commands
line	:	the function which will receive the line and do whatever it wants with it
close	:	the function to run when lines stop being read (either by the stop function returning true or the lines array depleting)
*****/
function parse( opts, data, write ){
	var str, lines,
		prevLines = [],
		out = [],
		closed = false,
		props = opts.props,
		absolute = props.absolute,
		step = props.step,
		first = Math.max(0, props.first),
		last = props.last || first-1,
		count = props.count,
		range = props.range || [first, count ? Math.max(first-1+count,last) : last],
		original = data.split( props.delimiter),
		commentDelim = props.commentDelim,
		trim = props.trim,
		ignoreEmpty = props.ignoreEmpty,
		join = props.join,
		eof = props.eof,
		index = 0,
		validIndex = 0,
		template = opts.template.slice(),
		indices = {},
		writer = {},
		parser = {
			index : indices
		};
				
	function setup(){
		//if the range is only a single range, then wrap it in another array
		if( typeof range[0] === "number" ) range = [range];
		
		Object.defineProperties( writer, {
			write : {
				value : addLine,
			},
		});
		
		Object.defineProperties( parser, {
			line : {
				set : function(s){ str = s },
				get : function(){ return str; }
			},
			close : {
				value : function(){
					tryClose();
					closed = true;
				}
			},
			hasNextLine : {
				value : hasNextLine,
			},
			goToLine : {
				value : nextLine,
			},
			nextLine : {
				get : nextLine,
			},
			write : {
				value : addLine,
			},
		});
			
		Object.defineProperties( indices, {
			absolute : {
				get : function(){ return index; }
			},
			valid : {
				get : function(){ return validIndex; }
			},
		});
		
		Object.freeze( parser );
		Object.freeze( indices );
	}

	function addLine(){
		var args = Array.prototype.slice.apply(arguments);
		
		args.forEach( function forEach( str ){
			if( str === undefined || str === null ) return;
			if( str.constructor === Array ) return str.forEach(forEach);
			out.push(str);
		});
	}
	
	function run( name, arg ){
		var arr = template.slice(),
			next = function(){
				var temp;
				
				if( arr.length ){
					temp = Templates[ getFirst(arr) ];
					if( temp && temp[name] ) temp[name]( next, props, arg );
					else next();
				}
				else if( opts[name] ) opts[name]( props, arg );
			};
		next();
	}
	
	function tryClose(){
		if( closed ) return;
		run('close', writer);
		if( write ) write( out.join( join ) + eof, function(){
			run('write')
		});
	}

	function clean( str ){
		var obj = {};
		Object.defineProperty( obj, 'index', {
			get : function(){return indices;}
		});
		if( commentDelim ) str = str.split( commentDelim )[0];
		if( trim ) str = str.trim();
		obj.line = str;
		run( 'clean', obj );
		return obj.line;
	}
	
	function canContinue(){
		return !count || (absolute ? 
			index < count :
			validIndex < count);
	}
	
	function isValid( str ){
		var obj = {
			line : str,
			valid : true
		};
		
		Object.defineProperty( obj, 'index', {
			get : function(){return indices;}
		});
		
		if( ignoreEmpty && !str ) return false;
		
		run('valid', obj );
		return obj.valid;
		
	}
	
	function nextLine( i, ignoreValid ){
		var i = i || step,
			valid_step = absolute ? 1 : i,
			absolute_step = absolute ? i : 1;
		
		str = null;
		
		while( !closed && valid_step && canContinue() ){
			i = absolute_step;
			//skip lines based on the absolute step
			while( i-- ) str = getFirst(lines);
			
			prevLines.push(str);
			
			if( !isString( str ) ) break;
			
			str = clean(str);
			
			if( isValid( str ) ) valid_step--;
			else str = null;
			
			index++;
		}
		
		if( isString(str) && !ignoreValid ) validIndex++;
		
		return str;
	}
	
	function hasNextLine( target ){
		var inc = absolute ? step : 1,
			i = inc-1,
			this_count = 0,
			stop = absolute && count ? last-index : lines.length,
			target = target || (absolute ? 1 : step);

		while( !closed && i < stop && (absolute || !count || validIndex+this_count < count) ){
			//return true if we have enough valid lines
			if( isValid( clean( lines[i] ) ) && ++this_count === target ) return true;
			i += inc;
		}
		return false;
	}
	
	function init(){
		run('init', writer);
	}
	
	function line(){
		run('line', parser);
	}
	
	function start(){
		setup();
		init();
		
		range.forEach( function( arr ){
			lines = original.slice();
			first = arr[0]-1;
			last = arr[1];
			count = last-first;
			index = 0;
			validIndex = 0;
			
			if( absolute ) lines.splice(0,first);
			//remove up to the first line
			else while( first-- ) nextLine(1,true);
			
			//handle the first line
			if( isString( nextLine(1) ) ) line();
			
			//go through every line in the array or until it reaches the end index
			while( isString( nextLine() ) ) line();
		});
		tryClose();
	}
	
	start();
};

/*****
The function to get a file from the web (accepts http or https)
opts	:		Object			:	The properties to ues when parsing the file
path	:		String			:	The path to the file on the web
write	:	Boolean | Function	:	False, or the 'write file' function
count	:		Number			:	The number of redirects
*****/
function get( opts, path, write, count ){
	var getter = path.startsWith('https://') ? https : http;
	
	//return if the redirect limit is reached
	if( count >= opts.props.maxRedirects ) return;
	
	getter.get( path, function (res) {
		var file = '';
		
		//handle a redirect with an increased redirect counter
		if (res.statusCode >= 300 && res.statusCode < 400 && 'location' in res.headers){
			path = url.resolve(path, res.headers.location);
			return get( opts, path, write, ++count );
		}
		
		res.on('data', function(chunk) {
			file += chunk;
		});
		
		res.on('end', function() {
			parse( opts, file, write )
		});
	});
};

/*****
To create a new properties object based on the input object and the input templates
props		:	Object	:	The input properties
template	:	Array	:	The templates the properties are based off of
*****/
function flattenProps( props, template ){
	var key,
		props = props || {},
		ret = {};
	
	//first copy the base properties
	for( key in Settings ) ret[key] = Settings[key];
	
	//add the default template to the front of array if it isn't already there
	if( template.indexOf('default') === -1 ) addFirst(template,'default');
	
	//then copy the template properties
	template.forEach(function(name){
		var temp, tempProps;
			
		temp = Templates[name];
		//return if the template doesnt exist or the template doesn't have properties
		if( !temp || !(tempProps = temp.props) ) return;
		
		for( key in tempProps ) ret[key] = tempProps[key];
	});
	
	//finally copy the input properties
	for( key in props ) ret[key] = props[key];
	
	return ret;
};

/*****
The function to create the line parser based on certain input settings

opts	:	Object		:	The input functions and settings
write	:	Boolean		:	Whether the function will write to a file or not

*****/
function apply( opts, write ){
	var opts = opts || {},
		//create a new props object using the inputs properties and the template
		props = opts.props = flattenProps(opts.props, opts.template = opts.template || []),
		path = opts.in || props.in,
		out = opts.out || props.out || path,
		sync = 'sync' in props ? props.sync : Settings.sync,
		encoding = props.encoding || Settings.encoding;
			
	if( !path ) return;
	
	//if we are writing, then redefine write to be a function
	if( write ) write = sync ? function( data, callback ){
		writeFileSync(out, data);
		callback();
	} : function( data, callback ){
		writeFile(out, data, callback);
	};
	
	//if it is a web source, then get the data
	if( path.match(/^https?:\/\//) ) return get( opts, path, write, 0 );
	
	if( sync ) return parse( opts, readFileSync( path, encoding ), write );
	
	readFile( path, encoding, function( err, data ){
		if(err) throw err;
		parse( opts, data, write );
	});
};

module.exports = {
	read : function( opts ){
		apply(opts, false);
	},
	write : function( opts ){
		apply(opts, true);
	},
	template : function( name, opts ){
		if( name in Templates ) return;
		Templates[name] = opts;
	},
	settings : function( opts ){
		var each;
		for(each in opts) Settings[each] = opts[each];
	}
}