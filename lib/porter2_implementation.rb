# coding: utf-8

# Implementation of the Porter 2 stemmer. String#porter2_stem is the main stemming procedure.

class String
  # Tidy up the word before we get down to the algorithm
  def porter2_tidy
    preword = self.to_s.strip.downcase
    
    # map apostrophe-like characters to apostrophes
    preword.gsub!(/‘/, "'")
    preword.gsub!(/’/, "'")

    preword
  end
     

  # Preprocess the word. 
  # Remove any initial ', if present. Then, set initial y, or y after a vowel, to Y
  #
  # (The comment to 'establish the regions R1 and R2' in the original description 
  # is an implementation optimisation that identifies where the regions start. As
  # no modifications are made to the word that affect those positions, you may want
  # to cache them now. This implementation doesn't do that.)
  def porter2_preprocess    
    w = self.dup

    # remove any initial apostrophe
    w.gsub!(/^'*(.)/, '\1')
    
    # set initial y, or y after a vowel, to Y
    w.gsub!(/^y/, "Y")
    w.gsub!(/(#{Porter2::V})y/, '\1Y')
    
    w
  end
    

  # R1 is the portion of the word after the first non-vowel after the first vowel
  # (with words beginning 'gener-', 'commun-', and 'arsen-' treated as special cases
  def porter2_r1
    if self =~ /^(gener|commun|arsen)(?<r1>.*)/
      Regexp.last_match(:r1)
    else
      self =~ /#{Porter2::V}#{Porter2::C}(?<r1>.*)$/
      Regexp.last_match(:r1) || ""
    end
  end


  # R2 is the portion of R1 (porter2_r1) after the first non-vowel after the first vowel
  def porter2_r2
    self.porter2_r1 =~ /#{Porter2::V}#{Porter2::C}(?<r2>.*)$/
    Regexp.last_match(:r2) || ""
  end
  

  # Returns true if the word ends with a short syllable
  def porter2_ends_with_short_syllable?
    self =~ /#{Porter2::SHORT_SYLLABLE}$/ ? true : false
  end


  # A word is short if it ends in a short syllable, and R1 is null
  def porter2_is_short_word?
    self.porter2_ends_with_short_syllable? and self.porter2_r1.empty?
  end
  

  # Search for the longest among the suffixes, 
  # * '
  # * 's
  # * 's'
  # and remove if found.
  def porter2_step0
    self.sub!(/(.)('s'|'s|')$/, '\1') || self
  end
  

  # Search for the longest among the following suffixes, and perform the action indicated. 
  # sses:: replace by ss 
  # ied, ies:: replace by i if preceded by more than one letter, otherwise by ie
  # s:: delete if the preceding word part contains a vowel not immediately before the s
  # us, ss:: do nothing
  def porter2_step1a
    if self =~ /sses$/
      self.sub(/sses$/, 'ss')
    elsif self =~ /..(ied|ies)$/
      self.sub(/(ied|ies)$/, 'i')
    elsif self =~ /(ied|ies)$/
      self.sub(/(ied|ies)$/, 'ie')
    elsif self =~ /(us|ss)$/
      self
    elsif self =~ /s$/
      if self =~ /(#{Porter2::V}.+)s$/
        self.sub(/s$/, '') 
      else
        self
      end
    else
      self
    end
  end
  

  # Search for the longest among the following suffixes, and perform the action indicated. 
  # eed, eedly:: replace by ee if the suffix is also in R1 
  # ed, edly, ing, ingly:: delete if the preceding word part contains a vowel and, 
  #                        after the deletion:
  #                        * if the word ends at, bl or iz: add e, or
  #                        * if the word ends with a double: remove the last letter, or
  #                        * if the word is short: add e
  # 
  # (If gb_english is +true+, treat the 'is' suffix as 'iz' above.)
  def porter2_step1b(gb_english = false)
    if self =~ /(eed|eedly)$/
      if self.porter2_r1 =~ /(eed|eedly)$/
        self.sub(/(eed|eedly)$/, 'ee')
      else
        self
      end
    else
      w = self.dup
      if w =~ /#{Porter2::V}.*(ed|edly|ing|ingly)$/
        w.sub!(/(ed|edly|ing|ingly)$/, '')
        if w =~ /(at|lb|iz)$/
          w += 'e' 
        elsif w =~ /is$/ and gb_english
          w += 'e' 
        elsif w =~ /#{Porter2::Double}$/
	  w.chop!
        elsif w.porter2_is_short_word?
          w += 'e'
        end
      end
      w
    end
  end


  # Replace a suffix of y or Y by i if it is preceded by a non-vowel which is 
  # not the first letter of the word.
  def porter2_step1c
    if self =~ /.+#{Porter2::C}(y|Y)$/
      self.sub(/(y|Y)$/, 'i')
    else
      self
    end
  end
  

  # Search for the longest among the suffixes listed in the keys of Porter2::STEP_2_MAPS. 
  # If one is found and that suffix occurs in R1, replace it with the value 
  # found in STEP_2_MAPS.
  #
  # (Suffixes 'ogi' and 'li' are treated as special cases in the procedure.)
  # 
  # (If gb_english is +true+, replace the 'iser' and 'isation' suffixes with
  # 'ise', similarly to how 'izer' and 'ization' are treated.)
  def porter2_step2(gb_english = false)
    r1 = self.porter2_r1
    s2m = Porter2::STEP_2_MAPS.dup
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
    elsif r1 =~ /li$/ and self =~ /(#{Porter2::Valid_LI})li$/
      self.sub(/li$/, '')
    elsif r1 =~ /ogi$/ and self =~ /logi$/
      self.sub(/ogi$/, 'og')
    else
      self
    end
  end
     

  # Search for the longest among the suffixes listed in the keys of Porter2::STEP_3_MAPS. 
  # If one is found and that suffix occurs in R1, replace it with the value 
  # found in STEP_3_MAPS.
  #
  # (Suffix 'ative' is treated as a special case in the procedure.)
  # 
  # (If gb_english is +true+, replace the 'alise' suffix with
  # 'al', similarly to how 'alize' is treated.)
  def porter2_step3(gb_english = false)
    if self =~ /ative$/ and self.porter2_r2 =~ /ative$/
      self.sub(/ative$/, '')
    else
      s3m = Porter2::STEP_3_MAPS.dup
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
  

  # Search for the longest among the suffixes listed in the keys of Porter2::STEP_4_MAPS. 
  # If one is found and that suffix occurs in R2, replace it with the value 
  # found in STEP_4_MAPS.
  #
  # (Suffix 'ion' is treated as a special case in the procedure.)
  # 
  # (If gb_english is +true+, delete the 'ise' suffix if found.)
  def porter2_step4(gb_english = false)
    if self.porter2_r2 =~ /ion$/ and self =~ /(s|t)ion$/
      self.sub(/ion$/, '')
    else
      s4m = Porter2::STEP_4_MAPS.dup
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


  # Search for the the following suffixes, and, if found, perform the action indicated. 
  # e:: delete if in R2, or in R1 and not preceded by a short syllable
  # l:: delete if in R2 and preceded by l
  def porter2_step5
    if self =~ /ll$/ and self.porter2_r2 =~ /l$/
      self.sub(/ll$/, 'l') 
    elsif self =~ /e$/ and self.porter2_r2 =~ /e$/ 
      self.sub(/e$/, '') 
    else
      r1 = self.porter2_r1
      if self =~ /e$/ and r1 =~ /e$/ and not self =~ /#{Porter2::SHORT_SYLLABLE}e$/
        self.sub(/e$/, '')
      else
        self
      end
    end
  end
  

  # Turn all Y letters into y
  def porter2_postprocess
    self.gsub(/Y/, 'y')
  end

  public
  
  # Perform the stemming procedure. If +gb_english+ is true, treat '-ise' and similar suffixes
  # as '-ize' in American English.
  def porter2_stem(gb_english = false)
    preword = self.porter2_tidy
    return preword if preword.length <= 2

    word = preword.porter2_preprocess
    
    if Porter2::SPECIAL_CASES.has_key? word
      Porter2::SPECIAL_CASES[word]
    else
      w1a = word.porter2_step0.porter2_step1a
      if Porter2::STEP_1A_SPECIAL_CASES.include? w1a 
	w1a
      else
        w1a.porter2_step1b(gb_english).porter2_step1c.porter2_step2(gb_english).porter2_step3(gb_english).porter2_step4(gb_english).porter2_step5.porter2_postprocess
      end
    end
  end  
  
  # A verbose version of porter2_stem that prints the output of each stage to STDOUT
  def porter2_stem_verbose(gb_english = false)
    preword = self.porter2_tidy
    puts "Preword: #{preword}"
    return preword if preword.length <= 2

    word = preword.porter2_preprocess
    puts "Preprocessed: #{word}"
    
    if Porter2::SPECIAL_CASES.has_key? word
      puts "Returning #{word} as special case #{Porter2::SPECIAL_CASES[word]}"
      Porter2::SPECIAL_CASES[word]
    else
      r1 = word.porter2_r1
      r2 = word.porter2_r2
      puts "R1 = #{r1}, R2 = #{r2}"
    
      w0 = word.porter2_step0 ; puts "After step 0:  #{w0} (R1 = #{w0.porter2_r1}, R2 = #{w0.porter2_r2})"
      w1a = w0.porter2_step1a ; puts "After step 1a: #{w1a} (R1 = #{w1a.porter2_r1}, R2 = #{w1a.porter2_r2})"
      
      if Porter2::STEP_1A_SPECIAL_CASES.include? w1a
        puts "Returning #{w1a} as 1a special case"
	w1a
      else
        w1b = w1a.porter2_step1b(gb_english) ; puts "After step 1b: #{w1b} (R1 = #{w1b.porter2_r1}, R2 = #{w1b.porter2_r2})"
        w1c = w1b.porter2_step1c ; puts "After step 1c: #{w1c} (R1 = #{w1c.porter2_r1}, R2 = #{w1c.porter2_r2})"
        w2 = w1c.porter2_step2(gb_english) ; puts "After step 2:  #{w2} (R1 = #{w2.porter2_r1}, R2 = #{w2.porter2_r2})"
        w3 = w2.porter2_step3(gb_english) ; puts "After step 3:  #{w3} (R1 = #{w3.porter2_r1}, R2 = #{w3.porter2_r2})"
        w4 = w3.porter2_step4(gb_english) ; puts "After step 4:  #{w4} (R1 = #{w4.porter2_r1}, R2 = #{w4.porter2_r2})"
        w5 = w4.porter2_step5 ; puts "After step 5:  #{w5}"
        wpost = w5.porter2_postprocess ; puts "After postprocess: #{wpost}"
        wpost
      end
    end
  end  
  
  alias stem porter2_stem

end

