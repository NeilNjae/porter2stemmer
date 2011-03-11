# coding: utf-8

# Constants for the Porter 2 stemmer
module Porter2

  # A non-vowel
  C = "[^aeiouy]"

  # A vowel: a e i o u y
  V = "[aeiouy]"

  # A non-vowel other than w, x, or Y
  CW = "[^aeiouywxY]"

  # Doubles created when adding a suffix: these are undoubled when stemmed
  Double = "(bb|dd|ff|gg|mm|nn|pp|rr|tt)"

  # A valid letter that can come before 'li' (or 'ly')
  Valid_LI = "[cdeghkmnrt]"

  # A specification for a short syllable.
  #
  # A short syllable in a word is either: 
  # 1. a vowel followed by a non-vowel other than w, x or Y and preceded by a non-vowel, or 
  # 2. a vowel at the beginning of the word followed by a non-vowel.
  #
  # (The original document is silent on whether sequences of two or more non-vowels make a
  # syllable long. But as this specification is only used to find sequences of non-vowel -
  # vowel - non-vowel - end-of-word, this ambiguity does not have an effect.)
  SHORT_SYLLABLE = "((#{C}#{V}#{CW})|(^#{V}#{C}))"

  # Suffix transformations used in porter2_step2.
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

  # Suffix transformations used in porter2_step3.
  # (ative ending dealt with in procedure)  
  STEP_3_MAPS = {"tional" => "tion",
                 "ational" => "ate",
                 "alize" => "al",
                 "icate" => "ic",
                 "iciti" => "ic",
                 "ical" => "ic",
                 "ful" => "",
                 "ness" => "" }
  
  # Suffix transformations used in porter2_step4.
  # (ion ending dealt with in procedure)
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
   
  # Special case words to stop processing after step 1a.
  STEP_1A_SPECIAL_CASES = %w[ inning outing canning herring earring proceed exceed succeed ]

end

