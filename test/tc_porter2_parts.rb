# coding: utf-8
# Porter 2 stemmer test file
#
# This file tests each stage of the stemmer individually.


$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'porter2'

#class String
#  public :porter2_preprocess, :porter2_r1, :porter2_r2
#end

class TestPorter2 < Test::Unit::TestCase

  def test_tidy
    assert_equal "abacde", "abacde".porter2_tidy
    assert_equal "abacde", "  abacde  ".porter2_tidy
    assert_equal "abacde", "ABACDE".porter2_tidy
    assert_equal "ab'cde", "ab‘cde".porter2_tidy
    assert_equal "ab'cde", "ab’cde".porter2_tidy
    assert_equal "ab'c'de", "ab’c’de".porter2_tidy
    assert_equal "ab'c'de", "ab‘c‘de".porter2_tidy
    assert_equal "''abacde", "’‘abacde".porter2_tidy
  end
  
  def test_preprocess
    assert_equal "abacde", "abacde".porter2_preprocess
    assert_equal "abacde", "''abacde".porter2_preprocess
    assert_equal "ab'c'de", "'ab'c'de".porter2_preprocess
    assert_equal "ab'c'de", "''ab'c'de".porter2_preprocess
    assert_equal "Yabac", "yabac".porter2_preprocess
    assert_equal "aYbc", "aybc".porter2_preprocess
    assert_equal "abacdeY", "abacdey".porter2_preprocess
    assert_equal "abaYde", "abayde".porter2_preprocess
    assert_equal "kabaYde", "kabayde".porter2_preprocess
    assert_equal "'", "'''".porter2_preprocess
  end
  
  def test_find_R1
    assert_equal "iful",  "beautiful".porter2_r1
    assert_equal "y", "beauty".porter2_r1
    assert_equal "", "beau".porter2_r1
    assert_equal "imadversion", "animadversion".porter2_r1
    assert_equal "kled", "sprinkled".porter2_r1
    assert_equal "harist", "eucharist".porter2_r1
    
    # special cases
    assert_equal "ate", "generate".porter2_r1
    assert_equal "ates", "generates".porter2_r1
    assert_equal "ated", "generated".porter2_r1
    assert_equal "al", "general".porter2_r1
    assert_equal "ally", "generally".porter2_r1
    assert_equal "ic", "generic".porter2_r1
    assert_equal "ically", "generically".porter2_r1
    assert_equal "ous", "generous".porter2_r1
    assert_equal "ously", "generously".porter2_r1

    assert_equal "al", "communal".porter2_r1
    assert_equal "ity", "community".porter2_r1
    assert_equal "e", "commune".porter2_r1
    
    assert_equal "ic", "arsenic".porter2_r1
    assert_equal "al", "arsenal".porter2_r1
  end
  
  def test_ends_with_short_syllable?
    assert_equal true, "rap".porter2_ends_with_short_syllable?
    assert_equal true, "trap".porter2_ends_with_short_syllable?
    assert_equal true, "entrap".porter2_ends_with_short_syllable?
    assert_equal true, "ow".porter2_ends_with_short_syllable? 
    assert_equal true, "on".porter2_ends_with_short_syllable?
    assert_equal true, "at".porter2_ends_with_short_syllable?
    assert_equal false, "uproot".porter2_ends_with_short_syllable? 
    assert_equal false, "bestow".porter2_ends_with_short_syllable?
    assert_equal false, "disturb".porter2_ends_with_short_syllable?
  end
  
  def test_is_short_word?
    short_words = %w[ bed shed shred hop ]
    long_words = %w[ bead embed beds ]
    short_words.each do |w|
      r1 = w.porter2_r1
      assert_equal true, w.porter2_is_short_word?, 
	  "#{w} should be short but classified as long"
    end
    long_words.each do |w|
      r1 = w.porter2_r1
      assert_equal false, w.porter2_is_short_word?, 
	  "#{w} should be long but classified as short"
    end
  end
  
  def test_find_R2
    assert_equal "ul",  "beautiful".porter2_r2
    assert_equal "", "beauty".porter2_r2
    assert_equal "", "beau".porter2_r2
    assert_equal "adversion", "animadversion".porter2_r2
    assert_equal "", "sprinkled".porter2_r2
    assert_equal "ist", "eucharist".porter2_r2
  end
  
  def test_step_0
    assert_equal "abac", "abac".step_0
    assert_equal "abac", "abac'".step_0
    assert_equal "abac", "abac's".step_0
    assert_equal "abac", "abac's'".step_0
    assert_equal "ab'c", "ab'c".step_0
    assert_equal "ab'sc", "ab'sc".step_0
    assert_equal "ab's'c", "ab's'c".step_0
    assert_equal "ab'sc", "ab'sc's".step_0
    assert_equal "'", "'".step_0
    assert_equal "'s", "'s".step_0
    assert_equal "'s", "'s'".step_0
  end
  
  def test_step_1a
    assert_equal "abacde", "abacde".step_1a
    assert_equal "abacess", "abacesses".step_1a
    assert_equal "tie", "ties".step_1a
    assert_equal "tie", "tied".step_1a
    assert_equal "cri", "cries".step_1a
    assert_equal "cri", "cried".step_1a
    assert_equal "gas", "gas".step_1a
    assert_equal "this", "this".step_1a
    assert_equal "gap", "gaps".step_1a
    assert_equal "kiwi", "kiwis".step_1a
    assert_equal "abacus", "abacus".step_1a
    assert_equal "abacess", "abacess".step_1a
  end
  
  def test_step_1b
    assert_equal "abacde", "abacde".step_1b
    words_non_gb = {"luxuriated" => "luxuriate", "luxuriating" => "luxuriate", 
             "hopping" => "hop", "hopped" => "hop",
             "hoped" => "hope", "hoping" => "hope",
             "atomized" => "atomize", "atomised" => "atomis",
             "addicted" => "addict", "bleed" => "bleed" }
    words_non_gb.each do |original, stemmed|
      assert_equal stemmed, original.step_1b, 
	  "#{original} should have stemmed to #{stemmed} but got #{original.step_1b(original.porter2_r1)} instead"
    end
    words_gb = {"luxuriated" => "luxuriate", "luxuriating" => "luxuriate", 
             "hopping" => "hop", "hopped" => "hop",
             "hoped" => "hope", "hoping" => "hope",
             "atomized" => "atomize", "atomised" => "atomise",
             "addicted" => "addict", "bleed" => "bleed" }
    words_gb.each do |original, stemmed|
      assert_equal stemmed, original.step_1b(true), 
	  "#{original} should have stemmed to #{stemmed} but got #{original.step_1b(original.porter2_r1)} instead"
    end
  end
  
  def test_step_1c
    assert_equal "cri", "cry".step_1c
    assert_equal "by", "by".step_1c
    assert_equal "saY", "saY".step_1c
    assert_equal "abbeY", "abbeY".step_1c
  end
  
  def test_step_2
    assert_equal "abac", "abac".step_2
    
    assert_equal "nationalize", "nationalization".step_2
    assert_equal "nationalisate", "nationalisation".step_2
    assert_equal "nationalize", "nationalization".step_2(true)
    assert_equal "nationalise", "nationalisation".step_2(true)
    # Repeat the steps to ensure that the english-gb behaviour isn't sticky
    assert_equal "nationalize", "nationalization".step_2(false)
    assert_equal "nationalisate", "nationalisation".step_2(false)
    assert_equal "nationalize", "nationalization".step_2
    assert_equal "nationalisate", "nationalisation".step_2
    
    assert_equal "nationalize", "nationalizer".step_2
    assert_equal "nationaliser", "nationaliser".step_2
    assert_equal "nationalize", "nationalizer".step_2(true)
    assert_equal "nationalise", "nationaliser".step_2(true)
    
    assert_equal "abaction", "abactional".step_2
    assert_equal "abacence", "abacenci".step_2
    assert_equal "abacance", "abacanci".step_2
    assert_equal "abacable", "abacabli".step_2
    assert_equal "abacent", "abacentli".step_2
    assert_equal "abacize", "abacizer".step_2
    assert_equal "abacize", "abacization".step_2
    assert_equal "abacate", "abacational".step_2
    assert_equal "abacate", "abacation".step_2
    assert_equal "abacate", "abacator".step_2
    assert_equal "abacal", "abacalism".step_2
    assert_equal "abacal", "abacaliti".step_2
    assert_equal "abacal", "abacalli".step_2
    assert_equal "abacful", "abacfulness".step_2
    assert_equal "abacous", "abacousli".step_2
    assert_equal "abacous", "abacousness".step_2
    assert_equal "abacive", "abaciveness".step_2
    assert_equal "abacive", "abaciviti".step_2
    assert_equal "abiliti", "abiliti".step_2
    assert_equal "abacble", "abacbiliti".step_2
    assert_equal "abacble", "abacbli".step_2
    assert_equal "abacful", "abacfulli".step_2
    assert_equal "abacless", "abaclessli".step_2
    assert_equal "abaclog", "abaclogi".step_2
    
    assert_equal "abac", "abacli".step_2
    assert_equal "abd", "abdli".step_2
    assert_equal "abe", "abeli".step_2
    assert_equal "abg", "abgli".step_2
    assert_equal "abh", "abhli".step_2
    assert_equal "abk", "abkli".step_2
    assert_equal "abm", "abmli".step_2
    assert_equal "abn", "abnli".step_2
    assert_equal "abr", "abrli".step_2
    assert_equal "abt", "abtli".step_2
    assert_equal "abali", "abali".step_2

    assert_equal "bad", "badli".step_2
    assert_equal "fluentli", "fluentli".step_2
    assert_equal "geolog", "geologi".step_2
  end
  
  def test_step_3
    assert_equal "abac", "abac".step_3("")
    
    assert_equal "national", "nationalize".step_3
    assert_equal "nationalise", "nationalise".step_3
    assert_equal "national", "nationalise".step_3(true)
    # Repeat the steps to ensure that the english-gb behaviour isn't sticky
    assert_equal "national", "nationalize".step_3(false)
    assert_equal "nationalise", "nationalise".step_3(false)
    assert_equal "national", "nationalize".step_3
    assert_equal "nationalise", "nationalise".step_3
    
    assert_equal "abaction", "abactional".step_3
    assert_equal "abacate", "abacational".step_3
    assert_equal "abacic", "abacicate".step_3
    assert_equal "abacic", "abaciciti".step_3
    assert_equal "abacic", "abacical".step_3
    assert_equal "abac", "abacful".step_3
    assert_equal "abac", "abacness".step_3
    
    assert_equal "abacabac", "abacabacative".step_3
    assert_equal "abacabac", "abacabacative".step_3
  
    assert_equal "dryness", "dryness".step_3
  end
  
  def test_step_4
    assert_equal "abac", "abac".step_4("")
    
    assert_equal "nation", "nationize".step_4
    assert_equal "nationise", "nationise".step_4
    assert_equal "nation", "nationize".step_4(true)
    assert_equal "nation", "nationise".step_4(true)
    assert_equal "nation", "nationize".step_4(false)
    assert_equal "nationise", "nationise".step_4(false)
    assert_equal "nation", "nationize".step_4()
    assert_equal "nationise", "nationise".step_4()
    
    assert_equal "abac", "abacal".step_4
    assert_equal "abac", "abacance".step_4
    assert_equal "abac", "abacence".step_4
    assert_equal "abac", "abacer".step_4
    assert_equal "abac", "abacic".step_4
    assert_equal "abacer", "abacerable".step_4
    assert_equal "abac", "abacible".step_4
    assert_equal "abac", "abacant".step_4
    assert_equal "abac", "abacement".step_4	# Check we handle overlapping suffixes properly
    assert_equal "abacac", "abacacement".step_4
    assert_equal "abacac", "abacacment".step_4
    assert_equal "abac", "abacment".step_4
    assert_equal "abac", "abacent".step_4
    assert_equal "abac", "abacism".step_4
    assert_equal "abac", "abacate".step_4
    assert_equal "abac", "abaciti".step_4
    assert_equal "abac", "abacous".step_4
    assert_equal "abac", "abacive".step_4
    assert_equal "abac", "abacize".step_4
    assert_equal "abacion", "abacion".step_4
    assert_equal "abacs", "abacsion".step_4
    assert_equal "abact", "abaction".step_4
    assert_equal "abction", "abction".step_4
    assert_equal "ablut", "ablution".step_4
    assert_equal "agreement", "agreement".step_4
    
    assert_equal "abcal", "abcal".step_4	# No removal if suffix isn't in R2
  end
  
  def test_step_5
    assert_equal "abac", "abac".step_5
    
    assert_equal "abacl", "abacll".step_5
    assert_equal "abcll", "abcll".step_5
    
    assert_equal "abc", "abc".step_5
    assert_equal "abl", "able".step_5
    assert_equal "abe", "abe".step_5
    assert_equal "abac", "abace".step_5
    assert_equal "bawac", "bawace".step_5
  end
  
  def test_porter2_postprocess
    assert_equal "abac", "abac".porter2_postprocess
    assert_equal "abacy", "abacy".porter2_postprocess
    assert_equal "abacy", "abacY".porter2_postprocess
    assert_equal "aybcy", "aYbcY".porter2_postprocess
    assert_equal "aybcy", "aYbcy".porter2_postprocess
  end

end
