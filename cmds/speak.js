
'use strict';

var parsers = require('../lib');
var _ = require('lodash');
var chalk = require('chalk');

if (typeof String.prototype.startsWith != 'function') {
  String.prototype.startsWith = function (str){
    return this.slice(0, str.length) == str;
  };
}

if (typeof String.prototype.endsWith != 'function') {
  String.prototype.endsWith = function (str){
    return this.slice(-str.length) == str;
  };
}

module.exports = function(program) {

  function peggyRepl(arg) {

    var readline = require('readline')
      , rl;

    var currentParser = {
      name: "",
      parser: {}
    }

    var buffer = [];

    function speak(grammar) {
      if (_.has(parsers, grammar)) {
        currentParser.name = grammar;
        currentParser.parser = parsers[currentParser.name];
        rl.setPrompt(grammar + chalk.green("?") + " ", grammar.length + 2);
      } else {
        console.log("Peggy doesn't know how to speak " + grammar);
      }
    }

    function parse(statement) {
      // console.log(statement);
      try {
        console.log(currentParser.parser.parse(statement.trim()));
      } catch (err) {
        console.error(err.message);
      }
    }

    rl = readline.createInterface(process.stdin, process.stdout, null);

    speak(Object.keys(parsers)[0]);

    if (arg) {
      speak(arg);
    }

    rl.on('line', function(line) {
      if (line === ':quit') {
        rl.close();
      } else if (line.startsWith(':speak')) {
        var grammar = line.substring(':speak'.length).trim();
        speak(grammar);
        rl.prompt();
      } else if (line === '') {
        if (buffer.length == 0) {
          buffer.push("");
        }
      } else {
        if (buffer.length > 0) {
          buffer.push(line);
        } else {
          parse(line);
          rl.prompt();
        }
      }

    });

    rl.on('close', function() {
      if (buffer.length > 0) {
        parse(buffer.join("\n"));
        buffer = [];
        rl.prompt();
      } else {
        console.log('Buh-bye');
        process.exit();
      }
    });

    rl.prompt();
  };

	program
		.command('speak')
		.version('0.1.0')
		.description('Speak to Peggy.')
    .action(peggyRepl);

};
