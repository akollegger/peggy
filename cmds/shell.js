'use strict';

var repl = require("repl");
var parsers = require('../lib');


module.exports = function(program) {

	program
		.command('shell')
		.version('0.0.1')
		.description('Interactive javascript shell')
		.action(function(/* Args here */){
      var local = repl.start('(pegjs) ');
      local.context.parsers = parsers;
		});

};
