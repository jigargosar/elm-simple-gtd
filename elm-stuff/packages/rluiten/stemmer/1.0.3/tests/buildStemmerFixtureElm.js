//
// Create StemmerFixture.elm from voc.txt and output.txt
// which are sample vocabulary and output
// from the porter stemmer website
// Copyright (c) 2016 Robin Luiten
//
// http://tartarus.org/~martin/PorterStemmer/index.html
//
// This is only required if you need to regenerate StemmerFixture.elm
// from voc.txt and output.txt files.
//
var fs = require('fs');

fs.readFile('voc.txt', 'utf8', function(inerr, indata) {
  if (inerr){
    return console.log(inerr);
  }
  console.log('length voc.txt ' + indata.length);

  fs.readFile('output.txt', 'utf8', function (outerr, outdata) {
    if (outerr) {
      return console.log(outerr);
    }
    console.log('length output.txt ' + outdata.length);

    var inwords = indata.split('\n');
    var outwords = outdata.split('\n');

    console.log('words in voc.txt ' + inwords.length
              + '\nwords in output.txt ' + outwords.length);

    if (inwords.length !== outwords.length) {
      return console.log("ERROR voc.txt and output.txt are not same length can't create Elm source file.");
    }


    var cases = [];
    for (i = 0; i < inwords.length; i++) {
      var word = inwords[i];
      var out = outwords[i];
      if (word && out) {
        tmp = `( "${word}", "${out}" )\n`;
        //console.log('tmp '+ tmp);
        cases[i] = tmp;
      }
    }

    allCases = cases.join("  , ");

    var template =
        `module StemmerFixture exposing (..)\n`
      + `\n`
      + `fixture = \n`
      + `  [ ${allCases}`
      + `  ]\n`;

    fs.writeFile('StemmerFixture.elm', template, 'utf8', function (err, data) {
      if (err) {
        return console.log(err);
      }
    });
    console.log("Successfully created StemmerFixture.elm with contents of voc.txt and output.txt");
  })
})
