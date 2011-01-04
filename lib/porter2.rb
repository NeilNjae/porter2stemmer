# coding: utf-8

# Porter 2 stemmer in Ruby.
#
# This is the Porter 2 stemming algorithm, as described at 
# http://snowball.tartarus.org/algorithms/english/stemmer.html
# The original paper is:
#
# Porter, 1980, "An algorithm for suffix stripping", _Program_, Vol. 14,
# no. 3, pp 130-137

module Stemmable
  # A non-vowel
  C = "[^aeiouy]"

  # A vowel
  V = "[aeiouy]"

  # A non-vowel other than w, x, or Y
  CW = "[^aeiouywxY]"

  # Doubles created when added a suffix: these are undoubled when stemmed
  Double = "(bb|dd|ff|gg|mm|nn|pp|rr|tt)"

  # A valid letter that can come before 'li'
  Valid_LI = "[cdeghkmnrt]"

  # A specification for a short syllable
  SHORT_SYLLABLE = "((#{C}#{V}#{CW})|(^#{V}#{C}))"

  # Suffix transformations used in Step 2.
  # (ogi, li endings dealt with in procedure)
  STEP_2_MAPS = {"tional" => "tion",
		 "enci" => "ence",
                 "anci" => "ance",
                 "abli" => "able",
                 "entli" => "ent",
                 "ization" => "ize",
                 "izer" => "ize",
                 "ational" => "ate",
                 "ation" => "ate",
                 "ator" => "ate",
                 "alism" => "al",
                 "aliti" => "al",
                 "alli" => "al",
                 "fulness" => "ful",
                 "ousli" => "ous",
                 "ousness" => "ous",
                 "iveness" => "ive",
                 "iviti" => "ive",
                 "biliti" => "ble",
                 "bli" => "ble",
                 "fulli" => "ful",
                 "lessli" => "less" }

  # Suffix transformations used in Step 3.
  # (ative ending dealt with in procedure)  
  STEP_3_MAPS = {"tional" => "tion",
                 "ational" => "ate",
                 "alize" => "al",
                 "icate" => "ic",
                 "iciti" => "ic",
                 "ical" => "ic",
                 "ful" => "",
                 "ness" => "" }
  
  # Suffix transformations used in Step 4.
  STEP_4_MAPS = {"al" => "",
                 "ance" => "",
                 "ence" => "",
                 "er" => "",
                 "ic" => "",
                 "able" => "",
                 "ible" => "",
                 "ant" => "",
                 "ement" => "",
                 "ment" => "",
                 "ent" => "",
                 "ism" => "",
                 "ate" => "",
                 "iti" => "",
                 "ous" => "",
                 "ive" => "",
                 "ize" => "" }
  
  # Special-case stemmings 
  SPECIAL_CASES = {"skis" => "ski",
                   "skies" => "sky",
                    
                   "dying" => "die",
                   "lying" => "lie",
                   "tying" => "tie",
                   "idly" =>  "idl",
                   "gently" => "gentl",
                   "ugly" => "ugli",
                   "early" => "earli",
                   "only" => "onli",
                   "singly" =>"singl",
                    
                   "sky" => "sky",
                   "news" => "news",
                   "howe" => "howe",
                   "atlas" => "atlas",
                   "cosmos" => "cosmos",
                   "bias" => "bias",
                   "andes" => "andes" }
   
  # Special case words to ignore after step 1a.
  STEP_1A_SPECIAL_CASES = %w[ inning outing canning herring earring proceed exceed succeed ]

  # Tidy up the word before we get down to the algorithm
  def porter2_tidy
    preword = self.to_s.strip.downcase
    
    # map apostrophe-like characters to apostrophes
    preword.gsub!(/‘/, "'")
    preword.gsub!(/’/, "'")

    preword
  end
     
  def porter2_preprocess    
    w = self.dup

    # remove any initial apostrophe
    w.gsub!(/^'*(.)/, '\1')
    
    # set initial y, or y after a vowel, to Y
    w.gsub!(/^y/, "Y")
    w.gsub!(/(#{V})y/, '\1Y')
    
    w
  end
    
  # The word after the first non-vowel after the first vowel
  def porter2_r1
    if self =~ /^(gener|commun|arsen)(?<r1>.*)/
      Regexp.last_match(:r1)
    else
      self =~ /#{V}#{C}(?<r1>.*)$/
      Regexp.last_match(:r1) || ""
    end
  end
  
  # R1 after the first non-vowel after the first vowel
  def porter2_r2
    self.porter2_r1 =~ /#{V}#{C}(?<r2>.*)$/
    Regexp.last_match(:r2) || ""
  end
  
  # A short syllable in a word is either 
  # 1. a vowel followed by a non-vowel other than w, x or Y and preceded by a non-vowel, or 
  # 2. a vowel at the beginning of the word followed by a non-vowel. 
  def porter2_ends_with_short_syllable?
    self =~ /#{SHORT_SYLLABLE}$/ ? true : false
  end

  # A word is short if it ends in a short syllable, and if R1 is null
  def porter2_is_short_word?
    self.porter2_ends_with_short_syllable? and self.porter2_r1.empty?
  end
  
  # Search for the longest among the suffixes, 
  # * '
  # * 's
  # * 's'
  # and remove if found.
  def step_0
    self.sub!(/(.)('s'|'s|')$/, '\1') || self
  end
  
  # Remove plural suffixes
  def step_1a
    if self =~ /sses$/
      self.sub(/sses$/, 'ss')
    elsif self =~ /..(ied|ies)$/
      self.sub(/(ied|ies)$/, 'i')
    elsif self =~ /(ied|ies)$/
      self.sub(/(ied|ies)$/, 'ie')
    elsif self =~ /(us|ss)$/
      self
    elsif self =~ /s$/
      if self =~ /(#{V}.+)s$/
        self.sub(/s$/, '') 
      else
        self
      end
    else
      self
    end
  end
  
  def step_1b(gb_english = false)
    if self =~ /(eed|eedly)$/
      if self.porter2_r1 =~ /(eed|eedly)$/
        self.sub(/(eed|eedly)$/, 'ee')
      else
        self
      end
    else
      w = self.dup
      if w =~ /#{V}.*(ed|edly|ing|ingly)$/
        w.sub!(/(ed|edly|ing|ingly)$/, '')
        if w =~ /(at|lb|iz)$/
          w += 'e' 
        elsif w =~ /is$/ and gb_english
          w += 'e' 
        elsif w =~ /#{Double}$/
	  w.chop!
        elsif w.porter2_is_short_word?
          w += 'e'
        end
      end
      w
    end
  end

  
  def step_1c
    if self =~ /.+#{C}(y|Y)$/
      self.sub(/(y|Y)$/, 'i')
    else
      self
    end
  end
  

  def step_2(gb_english = false)
    r1 = self.porter2_r1
    s2m = STEP_2_MAPS.dup
    if gb_english
      s2m["iser"] = "ise"
      s2m["isation"] = "ise"
    end
    step_2_re = Regexp.union(s2m.keys.map {|r| Regexp.new(r + "$")})
    if self =~ step_2_re
      if r1 =~ /#{$&}$/
        self.sub(/#{$&}$/, s2m[$&])
      else
        self
      end
    elsif r1 =~ /li$/ and self =~ /(#{Valid_LI})li$/
      self.sub(/li$/, '')
    elsif r1 =~ /ogi$/ and self =~ /logi$/
      self.sub(/ogi$/, 'og')
    else
      self
    end
  end
     
  
  def step_3(gb_english = false)
    if self =~ /ative$/ and self.porter2_r2 =~ /ative$/
      self.sub(/ative$/, '')
    else
      s3m = STEP_3_MAPS.dup
      if gb_english
	s3m["alise"] = "al"
      end
      step_3_re = Regexp.union(s3m.keys.map {|r| Regexp.new(r + "$")})
      r1 = self.porter2_r1
      if self =~ step_3_re and r1 =~ /#{$&}$/ 
	self.sub(/#{$&}$/, s3m[$&])
      else
	self
      end
    end
  end
  
  
  def step_4(gb_english = false)
    if self.porter2_r2 =~ /ion$/ and self =~ /(s|t)ion$/
      self.sub(/ion$/, '')
    else
      s4m = STEP_4_MAPS.dup
      if gb_english
        s4m["ise"] = ""
      end
      step_4_re = Regexp.union(s4m.keys.map {|r| Regexp.new(r + "$")})
      r2 = self.porter2_r2
      if self =~ step_4_re
        if r2 =~ /#{$&}/
          self.sub(/#{$&}$/, s4m[$&])
        else
          self
        end
      else
        self
      end
    end
  end

  
  def step_5
    if self =~ /ll$/ and self.porter2_r2 =~ /l$/
      self.sub(/ll$/, 'l') 
    elsif self =~ /e$/ and self.porter2_r2 =~ /e$/ 
      self.sub(/e$/, '') 
    else
      r1 = self.porter2_r1
      if self =~ /e$/ and r1 =~ /e$/ and not self =~ /#{SHORT_SYLLABLE}e$/
        self.sub(/e$/, '')
      else
        self
      end
    end
  end
  
  
  def porter2_postprocess
    self.gsub(/Y/, 'y')
  end

  
  def porter2_stem(gb_english = false)
    preword = self.porter2_tidy
    return preword if preword.length <= 2

    word = preword.porter2_preprocess
    
    if SPECIAL_CASES.has_key? word
      SPECIAL_CASES[word]
    else
      w1a = word.step_0.step_1a
      if STEP_1A_SPECIAL_CASES.include? w1a 
	w1a
      else
        w1a.step_1b(gb_english).step_1c.step_2(gb_english).step_3(gb_english).step_4(gb_english).step_5.porter2_postprocess
      end
    end
  end  
  
  def porter2_stem_verbose(gb_english = false)
    preword = self.porter2_tidy
    puts "Preword: #{preword}"
    return preword if preword.length <= 2

    word = preword.porter2_preprocess
    puts "Preprocessed: #{word}"
    
    if SPECIAL_CASES.has_key? word
      puts "Returning #{word} as special case #{SPECIAL_CASES[word]}"
      SPECIAL_CASES[word]
    else
      r1 = word.porter2_r1
      r2 = word.porter2_r2
      puts "R1 = #{r1}, R2 = #{r2}"
    
      w0 = word.step_0 ; puts "After step 0:  #{w0} (R1 = #{w0.porter2_r1}, R2 = #{w0.porter2_r2})"
      w1a = w0.step_1a ; puts "After step 1a: #{w1a} (R1 = #{w1a.porter2_r1}, R2 = #{w1a.porter2_r2})"
      
      if STEP_1A_SPECIAL_CASES.include? w1a
        puts "Returning #{w1a} as 1a special case"
	w1a
      else
        w1b = w1a.step_1b(gb_english) ; puts "After step 1b: #{w1b} (R1 = #{w1b.porter2_r1}, R2 = #{w1b.porter2_r2})"
        w1c = w1b.step_1c ; puts "After step 1c: #{w1c} (R1 = #{w1c.porter2_r1}, R2 = #{w1c.porter2_r2})"
        w2 = w1c.step_2(gb_english) ; puts "After step 2:  #{w2} (R1 = #{w2.porter2_r1}, R2 = #{w2.porter2_r2})"
        w3 = w2.step_3(gb_english) ; puts "After step 3:  #{w3} (R1 = #{w3.porter2_r1}, R2 = #{w3.porter2_r2})"
        w4 = w3.step_4(gb_english) ; puts "After step 4:  #{w4} (R1 = #{w4.porter2_r1}, R2 = #{w4.porter2_r2})"
        w5 = w4.step_5 ; puts "After step 5:  #{w5}"
        wpost = w5.porter2_postprocess ; puts "After postprocess: #{wpost}"
        wpost
      end
    end
  end  
  
  alias stem porter2_stem

end

# Add stem method to all Strings
class String
  include Stemmable
  
  # private :porter2_preprocess, :porter2_r1, :porter2_r2
end
