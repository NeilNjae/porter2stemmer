# coding: utf-8
# Porter 2 stemmer test file
#
# This file tests each stage of the stemmer individually.

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'porter2'

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
    assert_equal "kabyaYde", "kabyayde".porter2_preprocess
    assert_equal "'", "'''".porter2_preprocess
  end
  
  def test_R1
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
  
  def test_R2
    assert_equal "ul",  "beautiful".porter2_r2
    assert_equal "", "beauty".porter2_r2
    assert_equal "", "beau".porter2_r2
    assert_equal "adversion", "animadversion".porter2_r2
    assert_equal "", "sprinkled".porter2_r2
    assert_equal "ist", "eucharist".porter2_r2
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
  
  def test_step_0
    assert_equal "abac", "abac".porter2_step0
    assert_equal "abac", "abac'".porter2_step0
    assert_equal "abac", "abac's".porter2_step0
    assert_equal "abac", "abac's'".porter2_step0
    assert_equal "ab'c", "ab'c".porter2_step0
    assert_equal "ab'sc", "ab'sc".porter2_step0
    assert_equal "ab's'c", "ab's'c".porter2_step0
    assert_equal "ab'sc", "ab'sc's".porter2_step0
    assert_equal "'", "'".porter2_step0
    assert_equal "'s", "'s".porter2_step0
    assert_equal "'s", "'s'".porter2_step0
  end
  
  def test_step_1a
    assert_equal "abacde", "abacde".porter2_step1a
    assert_equal "abacess", "abacesses".porter2_step1a
    assert_equal "tie", "ties".porter2_step1a
    assert_equal "tie", "tied".porter2_step1a
    assert_equal "cri", "cries".porter2_step1a
    assert_equal "cri", "cried".porter2_step1a
    assert_equal "gas", "gas".porter2_step1a
    assert_equal "this", "this".porter2_step1a
    assert_equal "gap", "gaps".porter2_step1a
    assert_equal "kiwi", "kiwis".porter2_step1a
    assert_equal "abacus", "abacus".porter2_step1a
    assert_equal "abacess", "abacess".porter2_step1a
  end
  
  def test_step_1b
    assert_equal "abacde", "abacde".porter2_step1b
    words_non_gb = {"luxuriated" => "luxuriate", "luxuriating" => "luxuriate", 
             "hopping" => "hop", "hopped" => "hop",
             "hoped" => "hope", "hoping" => "hope",
             "atomized" => "atomize", "atomised" => "atomis",
             "addicted" => "addict", "bleed" => "bleed" }
    words_non_gb.each do |original, stemmed|
      assert_equal stemmed, original.porter2_step1b, 
	  "#{original} should have stemmed to #{stemmed} but got #{original.porter2_step1b(original.porter2_r1)} instead"
    end
    words_gb = {"luxuriated" => "luxuriate", "luxuriating" => "luxuriate", 
             "hopping" => "hop", "hopped" => "hop",
             "hoped" => "hope", "hoping" => "hope",
             "atomized" => "atomize", "atomised" => "atomise",
             "addicted" => "addict", "bleed" => "bleed" }
    words_gb.each do |original, stemmed|
      assert_equal stemmed, original.porter2_step1b(true), 
	  "#{original} should have stemmed to #{stemmed} but got #{original.porter2_step1b(original.porter2_r1)} instead"
    end
  end
  
  def test_step_1c
    assert_equal "cri", "cry".porter2_step1c
    assert_equal "by", "by".porter2_step1c
    assert_equal "saY", "saY".porter2_step1c
    assert_equal "abbeY", "abbeY".porter2_step1c
  end
  
  def test_step_2
    assert_equal "abac", "abac".porter2_step2
    
    assert_equal "nationalize", "nationalization".porter2_step2
    assert_equal "nationalisate", "nationalisation".porter2_step2
    assert_equal "nationalize", "nationalization".porter2_step2(true)
    assert_equal "nationalise", "nationalisation".porter2_step2(true)
    # Repeat the steps to ensure that the english-gb behaviour isn't sticky
    assert_equal "nationalize", "nationalization".porter2_step2(false)
    assert_equal "nationalisate", "nationalisation".porter2_step2(false)
    assert_equal "nationalize", "nationalization".porter2_step2
    assert_equal "nationalisate", "nationalisation".porter2_step2
    
    assert_equal "nationalize", "nationalizer".porter2_step2
    assert_equal "nationaliser", "nationaliser".porter2_step2
    assert_equal "nationalize", "nationalizer".porter2_step2(true)
    assert_equal "nationalise", "nationaliser".porter2_step2(true)
    
    assert_equal "abaction", "abactional".porter2_step2
    assert_equal "abacence", "abacenci".porter2_step2
    assert_equal "abacance", "abacanci".porter2_step2
    assert_equal "abacable", "abacabli".porter2_step2
    assert_equal "abacent", "abacentli".porter2_step2
    assert_equal "abacize", "abacizer".porter2_step2
    assert_equal "abacize", "abacization".porter2_step2
    assert_equal "abacate", "abacational".porter2_step2
    assert_equal "abacate", "abacation".porter2_step2
    assert_equal "abacate", "abacator".porter2_step2
    assert_equal "abacal", "abacalism".porter2_step2
    assert_equal "abacal", "abacaliti".porter2_step2
    assert_equal "abacal", "abacalli".porter2_step2
    assert_equal "abacful", "abacfulness".porter2_step2
    assert_equal "abacous", "abacousli".porter2_step2
    assert_equal "abacous", "abacousness".porter2_step2
    assert_equal "abacive", "abaciveness".porter2_step2
    assert_equal "abacive", "abaciviti".porter2_step2
    assert_equal "abiliti", "abiliti".porter2_step2
    assert_equal "abacble", "abacbiliti".porter2_step2
    assert_equal "abacble", "abacbli".porter2_step2
    assert_equal "abacful", "abacfulli".porter2_step2
    assert_equal "abacless", "abaclessli".porter2_step2
    assert_equal "abaclog", "abaclogi".porter2_step2
    
    assert_equal "abac", "abacli".porter2_step2
    assert_equal "abd", "abdli".porter2_step2
    assert_equal "abe", "abeli".porter2_step2
    assert_equal "abg", "abgli".porter2_step2
    assert_equal "abh", "abhli".porter2_step2
    assert_equal "abk", "abkli".porter2_step2
    assert_equal "abm", "abmli".porter2_step2
    assert_equal "abn", "abnli".porter2_step2
    assert_equal "abr", "abrli".porter2_step2
    assert_equal "abt", "abtli".porter2_step2
    assert_equal "abali", "abali".porter2_step2

    assert_equal "bad", "badli".porter2_step2
    assert_equal "fluentli", "fluentli".porter2_step2
    assert_equal "geolog", "geologi".porter2_step2
  end
  
  def test_step_3
    assert_equal "abac", "abac".porter2_step3("")
    
    assert_equal "national", "nationalize".porter2_step3
    assert_equal "nationalise", "nationalise".porter2_step3
    assert_equal "national", "nationalise".porter2_step3(true)
    # Repeat the steps to ensure that the english-gb behaviour isn't sticky
    assert_equal "national", "nationalize".porter2_step3(false)
    assert_equal "nationalise", "nationalise".porter2_step3(false)
    assert_equal "national", "nationalize".porter2_step3
    assert_equal "nationalise", "nationalise".porter2_step3
    
    assert_equal "abaction", "abactional".porter2_step3
    assert_equal "abacate", "abacational".porter2_step3
    assert_equal "abacic", "abacicate".porter2_step3
    assert_equal "abacic", "abaciciti".porter2_step3
    assert_equal "abacic", "abacical".porter2_step3
    assert_equal "abac", "abacful".porter2_step3
    assert_equal "abac", "abacness".porter2_step3
    
    assert_equal "abacabac", "abacabacative".porter2_step3
    assert_equal "abacabac", "abacabacative".porter2_step3
  
    assert_equal "dryness", "dryness".porter2_step3
  end
  
  def test_step_4
    assert_equal "abac", "abac".porter2_step4("")
    
    assert_equal "nation", "nationize".porter2_step4
    assert_equal "nationise", "nationise".porter2_step4
    assert_equal "nation", "nationize".porter2_step4(true)
    assert_equal "nation", "nationise".porter2_step4(true)
    assert_equal "nation", "nationize".porter2_step4(false)
    assert_equal "nationise", "nationise".porter2_step4(false)
    assert_equal "nation", "nationize".porter2_step4()
    assert_equal "nationise", "nationise".porter2_step4()
    
    assert_equal "abac", "abacal".porter2_step4
    assert_equal "abac", "abacance".porter2_step4
    assert_equal "abac", "abacence".porter2_step4
    assert_equal "abac", "abacer".porter2_step4
    assert_equal "abac", "abacic".porter2_step4
    assert_equal "abacer", "abacerable".porter2_step4
    assert_equal "abac", "abacible".porter2_step4
    assert_equal "abac", "abacant".porter2_step4
    assert_equal "abac", "abacement".porter2_step4	# Check we handle overlapping suffixes properly
    assert_equal "abacac", "abacacement".porter2_step4
    assert_equal "abacac", "abacacment".porter2_step4
    assert_equal "abac", "abacment".porter2_step4
    assert_equal "abac", "abacent".porter2_step4
    assert_equal "abac", "abacism".porter2_step4
    assert_equal "abac", "abacate".porter2_step4
    assert_equal "abac", "abaciti".porter2_step4
    assert_equal "abac", "abacous".porter2_step4
    assert_equal "abac", "abacive".porter2_step4
    assert_equal "abac", "abacize".porter2_step4
    assert_equal "abacion", "abacion".porter2_step4
    assert_equal "abacs", "abacsion".porter2_step4
    assert_equal "abact", "abaction".porter2_step4
    assert_equal "abction", "abction".porter2_step4
    assert_equal "ablut", "ablution".porter2_step4
    assert_equal "agreement", "agreement".porter2_step4
    
    assert_equal "abcal", "abcal".porter2_step4	# No removal if suffix isn't in R2
  end
  
  def test_step_5
    assert_equal "abac", "abac".porter2_step5
    
    assert_equal "abacl", "abacll".porter2_step5
    assert_equal "abcll", "abcll".porter2_step5
    
    assert_equal "abc", "abc".porter2_step5
    assert_equal "abl", "able".porter2_step5
    assert_equal "abe", "abe".porter2_step5
    assert_equal "abac", "abace".porter2_step5
    assert_equal "bawac", "bawace".porter2_step5
  end
  
  def test_porter2_postprocess
    assert_equal "abac", "abac".porter2_postprocess
    assert_equal "abacy", "abacy".porter2_postprocess
    assert_equal "abacy", "abacY".porter2_postprocess
    assert_equal "aybcy", "aYbcY".porter2_postprocess
    assert_equal "aybcy", "aYbcy".porter2_postprocess
  end

end
