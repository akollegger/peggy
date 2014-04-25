textWorks
  = "wc:" space* wc:wordCount { return wc; }
  / "lc:" space* lc:letterCount { return lc; }

letterCount = w:(iw:word space? { return iw; })* {
  var total = 0;
  for (var i=0; i < w.length; i++) {
    total += w[i].length;
  }
  return total;
}

wordCount = w:(word space?)* { return w.length; }

word = letter+

letter = [a-zA-Z0-9]

space = " "
