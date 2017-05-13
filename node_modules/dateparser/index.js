'use strict';
/**
 * A human language relative date parser
 *
 * Copyright (c) 2015 by Jeff Haynie
 */
var repeating = 'on every, every other, every, once, once per, at, at the, on, on the, each, exactly, next, after',
	relativeTime = /^(on|at|after)$/,
	times = {
		ms: 1,
		millisecond: 1,
		s: 1000,
		sec: 1000,
		second: 1000,
		m: 60000,
		min: 60000,
		minute: 60000,
		h: 3.6e+6,
		hr: 3.6e+6,
		hour: 3.6e+6,
		hourly: 3.6e+6,
		d: 8.64e+7,
		day: 8.64e+7,
		daily: 8.64e+7,
		w: 6.048e+8,
		week: 6.048e+8,
		weekly: 6.048e+8,
		mth: 2.63e+9,
		month: 2.63e+9,
		monthly: 2.63e+9,
		qtr: 2.63e+9 * 3,
		quarter: 2.63e+9 * 3,
		quarterly: 2.63e+9 * 3,
		y: 3.156e+10,
		yr: 3.156e+10,
		year: 3.156e+10,
		yearly: 3.156e+10,
		annual: 3.156e+10,
		annually: 3.156e+10
	},
	counts = {
		zero: {value: 0, ty: false, teen: false, twen: false, fif: false, thir: false, hundred: false, thousand: false},
		one: {value: 1, ty: false, teen: false, twen: false, fif: false, thir: false},
		two: {value: 2, ty: false, teen: false, twen: false, fif: false, thir: false},
		thir: {value: 3, hundred: false, singular: false, twen: false, fif: false, thir: false},
		three: {value: 3, teen: false, ty: false, twen: false, fif: false, thir: false},
		four: {value: 4, twen: false, fif: false, thir: false},
		fif: {value: 5, single: true, hundred: false, thousand: false, twen: false, fif: false, thir: false},
		five: {value: 5, teen: false, ty: false, twen: false, fif: false, thir: false},
		six: {value: 6, twen: false, fif: false, thir: false},
		seven: {value: 7, twen: false, fif: false, thir: false},
		eight: {value: 8, teen: 'eigh', ty: 'eigh', twen: false, fif: false, thir: false},
		nine: {value: 9, twen: false, fif: false, thir: false},
		ten: {value: 10, hundred: false, teen: false, ty: false, twen: false, fif: false, thir: false},
		eleven: {value: 11, teen: false, ty: false, twen: false, fif: false, thir: false},
		twelve: {value: 12, teen: false, ty: false, twen: false, fif: false, thir: false},
		twen: {value: 2, single: true, teen: false, hundred: false, thousand: false, twen: false, fif: false, thir: false},
		teen: {value: 10, ty: false, addition: true, teen: false, hundred: false, thousand: false, twen: false, fif: false, thir: false},
		ty: {value: 10, single: true, multiplier: true, ty: false, hundred: false, thousand: false},
		hundred: {value: 100, prefix: ' ', multiplier: true, singular: true, twen: false, fif: false, thir: false, thousand: false, hundred: false},
		thousand: {value: 1000, prefix: ' ', multiplier: true, singular: true, twen: false, fif: false, thir: false, hundred: false, thousand: false}
	},
	relativeDate = '(from)?\\s?now';

function makeCountGroup () {
	var items = [],
		values = {};
	Object.keys(counts).forEach(function (k) {
		var e = counts[k];
		var value = e.value;
		if (!e.multiplier && !e.addition && (e.singular || e.singular === undefined) && !e.single) {
			items.push(k);
			values[k] = value;
		} else if (e.multiplier) {
			if (!e.single) {
				items.push(k);
				values[k] = value;
			}
		} else if (e.addition) {
			Object.keys(counts).forEach(function (kk) {
				var ee = counts[kk];
				if (!ee.multiplier && (ee[k] || ee[k] === undefined)) {
					value = (ee[k] || String(kk)) + (e.prefix || '') + String(k);
					items.push(value);
					values[value] = e.value + ee.value;
				}
			});
		}
		Object.keys(counts).forEach(function (kk) {
			var ee = counts[kk];
			if ((ee[k] || ee[k]==undefined) && (e[kk] || e[kk]==undefined) && ee.multiplier) {
				value = (e[kk] || k) + (ee.prefix || '') + kk;
				items.push(value);
				values[value] = ee.addition ? ee.value + e.value : ee.value * e.value;
			}
		});
	});
	items.sort(function (a, b) {
		if (a.length > b.length) {
			return -1;
		} else if (a.length < b.length) {
			return 1;
		}
		return 0;
	});
	return {
		re: '((' + items.join('|') + ')?\\s*('+ items.join('|') +')?)',
		values: values
	};
}

function makeGroup(str, optional) {
	return '(' + str.split(',').map(function (s) {
		return s.trim();
	}).join('|') + ')' + (optional ? '?' : '');
}

var repeatGroup = makeGroup(repeating, true) + '\\s*';
var countGroup = makeCountGroup();
var timeGroup = '(' + Object.keys(times).join('|') + ')?s?';
var numberGroup = '(\\d+)*';
var relativeGroup = makeGroup(relativeDate, true);
var re = new RegExp('^' + repeatGroup + numberGroup + '\\s*' + countGroup.re + '\\s*' + timeGroup + '\\s*' + relativeGroup + '$');
// console.log(re);
/**
 * parse input into a numeric value of time in milliseconds
 */
function parse(input) {
	var now = Date.now();
	if (typeof(input)==='number') {
		return {value:input, relative: true};
	}
	var match = re.exec(input);
	if (!match) { return null; }
	var relative = false,
		multiplier = 1;
	// console.log(match);
	if (match.length > 1) {
		if (match[1] && relativeTime.test(match[1])) {
			relative = true;
		} else if (match[1] === 'every other') {
			multiplier = 2;
		}
	}
	var value = (match.length > 3 && +match[2] || 0);
	value += (match.length > 4 && match[4] && countGroup.values[match[4]] || 0) +
			(match.length > 5 && match[5] && countGroup.values[match[5]] || 0);
	if (match.length > 6 && match[6] && times[match[6]]) {
		if (value > 0) {
			value *= times[match[6]];
		} else {
			value = times[match[6]];
		}
	}
	if ((relative && match[6]) || (match.length > 7 && match[7] && !relative)) {
		value =  now + value;
		relative = true;
	}
	return {value:value * multiplier, relative: relative};
}

function pluralize(v, label) {
	v = Math.floor(v);
	return v + ' ' + label + (v > 1 ? 's' : '');
}

function format (value) {
	if (typeof(value) === 'string') { return format(parse(value)); }
	var moment = require('moment');
	if (value.relative) {
		return moment(value.value).fromNow();
	} else {
		if (value.value === times.ms) {
			return 'every ms';
		} else if (value.value < times.second) {
			return 'every ' + value.value + ' ms';
		} else if (value.value === times.second) {
			return 'every second';
		} else if (value.value < times.minute) {
			var v = Math.floor(value.value / times.second);
			return 'every ' + pluralize(value.value / times.second, 'second');
		} else if (value.value === times.minute) {
			return 'every minute';
		} else if (value.value < times.hour) {
			return 'every ' + pluralize(value.value / times.minute, 'minute');
		} else if (value.value === times.hour) {
			return 'every hour';
		} else if (value.value < times.day) {
			return 'every ' + pluralize(value.value / times.day, 'hour');
		} else if (value.value === times.day) {
			return 'every day';
		} else if (value.value === times.week) {
			return 'every week';
		} else if (value.value < times.month && (value.value / times.week) > 1) {
			return 'every ' + pluralize(value.value / times.week, 'week');
		} else if (value.value < times.month) {
			return 'every ' + pluralize(value.value / times.day, 'day');
		} else if (value.value === times.day) {
			return 'every day';
		} else if (value.value === times.month) {
			return 'every month';
		} else if (value.value < times.year) {
			return 'every ' + pluralize(value.value / times.month, 'month');
		} else if (value.value === times.year) {
			return 'every year';
		} else {
			return 'every ' + pluralize(value.value / times.year, 'year');
		}
	}
}

exports.parse = parse;
exports.format = format;

// browser global shim
if (typeof(window) === 'object') {
	window.dateparser = exports;
}
