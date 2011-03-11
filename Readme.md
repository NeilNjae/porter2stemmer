The Porter 2 stemmer
====================
This is the Porter 2 stemming algorithm, as described at 
http://snowball.tartarus.org/algorithms/english/stemmer.html
The original paper is:

Porter, 1980, "An algorithm for suffix stripping", _Program_, Vol. 14,
no. 3, pp 130-137

Features of this implementation
===============================
This stemmer is written in pure Ruby, making it easy to modify for language variants. 
For instance, the original Porter stemmer only works for American English and does
not recognise British English's '-ise' as an alternate spelling of '-ize'. This 
implementation has been extended to handle correctly British English.

This stemmer also features a comprehensive test set of over 29,000 words, taken from the 
{Porter 2 stemmer website}[http://snowball.tartarus.org/algorithms/english/stemmer.html].

Files
=====
Constants for the stemmer are in the Porter2 module.

Procedures that implement the stemmer are added to the String class.

The stemmer algorithm is implemented in the String#porter2_stem procedure.

Internationalisation
====================
There isn't much, as this is a stemmer that only works for English.

The `gb_english` flag to the various procedures allows the stemmer to treat the British 
English '-ise' the same as the American English '-ize'.

Longest suffixes
================
Several places in the algorithm require matching the longest suffix of a word. The 
regexp engine in Ruby 1.9 seems to handle alterntives in regexps by finding the 
alternative that matches at the first position in the string. As we're only talking 
about suffixes, that first match is also the longest suffix. If the regexp engine changes,
this behaviour may change and break the stemmer.

Usage
=====
Call the String#porter2_stem or String#stem methods on a string to return its stem
    "consistency".stem       # => "consist"
    "knitting".stem          # => "knit"
    "articulated".stem       # => "articul"
    "nationalize".stem       # => "nation"
    "nationalise".stem       # => "nationalis"
    "nationalise".stem(true) # => "nation"

Author
======
The Porter 2 stemming algorithm was developed by 
[Martin Porter](http://snowball.tartarus.org/algorithms/english/stemmer.html). 
This implementation is by [Neil Smith](http://www.njae.me.uk).

