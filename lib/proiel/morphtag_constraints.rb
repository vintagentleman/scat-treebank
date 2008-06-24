#!/usr/bin/env ruby
#
# morphtag_constraints.rb - Morphology tag constraints
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
require 'singleton'
require 'logos'

module PROIEL
  # Definition and test functions for constraints on PROIEL morphtags.
  # This is a singleton class and should be accessed using the
  # +instance+ method.
  class MorphtagConstraints
    include Singleton

    # Regexps for matching certain sets of features in positional tags. 
    BLACK_LIST_REGEXPS = {
      :art =>           /^S/,

      :dual =>          /^...d/,

      :gender =>        /^.......[^-]/,

      :voc =>           /^........v/,
      :abl =>           /^........b/,
      :ins =>           /^........i/,
      :loc =>           /^........l/,

      :resultative =>   /^....s/,
      :past =>          /^....u/,
      :aorist =>        /^....a/,
      
      :optative =>      /^.....o/,

      :middle =>        /^......[emnd]/,

      :animacy =>       /^..........[^\-]/,

      :strength =>      /^...........[^\-]/,
    }

    # A specification of feature sets that should be treated as invalid
    # in specific languages
    LANGUAGE_BLACK_LISTS = {
      :la =>  [ :art, :dual,                      :ins,       :aorist, :resultative, :past, :optative, :middle, :animacy, :strength, ],
      :grc => [       :dual,                :abl, :ins, :loc,          :resultative, :past,                     :animacy, :strength, ],
      :hy  => [ :art, :dual, :gender, :voc, :abl, :ins,                :resultative, :past, :optative, :middle, :animacy, :strength, ],
      :got => [ :art,                 :voc, :abl, :ins, :loc, :aorist, :resultative,        :optative, :middle, :animacy, :strength, ],
      :cu  => [ :art,                       :abl,                                           :optative, :middle,                      ],
    }

    private

    def initialize
      @fst = Logos::SFST::RegularTransducer.new(File.join(File.dirname(__FILE__), "morphtag_constraints.a"))
      @tag_spaces = {}
    end

    def make_tag_space(language)
      tags = []
      @fst.generate_language(:levels => :upper) do |t|
        t = t.join
        if language
          tags << t if is_valid_in_language?(t, language)
        else
          tags << t
        end
      end
      tags
    end

    def is_valid_in_language?(tag, language)
      black_list = LANGUAGE_BLACK_LISTS[language]

      if black_list and black_list.any? { |b| BLACK_LIST_REGEXPS[b].match(tag) }
        false
      else
        true
      end
    end

    public

    def tag_space(language = nil)
      language = language.to_sym if language
      @tag_spaces[language] ||= make_tag_space(language)
    end

    # Tests if a PROIEL morphtag is valid, i.e. that it does not violate
    # any of the specified constraints. If +language+ is specified, 
    # additional language specific constraints are taken into account.
    def is_valid?(morphtag, language = nil)
      language = language.to_sym if language
      if @fst.analyze(morphtag)
        return is_valid_in_language?(morphtag, language) if language
        true
      else
        false
      end
    end

    def to_features(morphtag)
      s = nil
      @fst.analyze(morphtag) do |f|
        raise "Multiple analyses" if s
        s = f
      end
      s
    end
  end
end
