require 'rubygems'
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'porter2stemmer'

require 'test_porter2stemmer_parts'
require 'test_porter2stemmer_full'

