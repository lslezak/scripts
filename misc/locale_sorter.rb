#! /usr/bin/env ruby

# Sort strings using the current locale, uses native strcoll() glibc function.
#
# Examples:
#
#  LC_ALL=cs_CZ.utf-8 ./locale_sorter.rb z č ch a c ď ž x
#    -> ["a", "c", "č", "ď", "ch", "x", "z", "ž"]
#
#  LC_ALL=da_DK.utf-8 ./locale_sorter.rb Aarhus Aalborg Assens
#    -> ["Assens", "Aalborg", "Aarhus"]
#

require "fiddle/import"

module LocaleSorter
  # glibc wrapper, see https://ruby-doc.org/stdlib-2.5.0/libdoc/fiddle/rdoc/Fiddle/Importer.html
  module Glibc
    extend Fiddle::Importer
    dlload "libc.so.6"

    extern "int strcoll(char*, char*)"
    extern "char* setlocale(int, char*)"
  end

  SORTER = proc do |x, y|
    Glibc.strcoll(x, y)
  end

  # initialize the locale, equivalent of `setlocale(LC_ALL, "")` in C
  def self.init_locale
    # LC_ALL = 6 in glibc, see locale.h...
    Glibc.setlocale(6, "")  
  end
end

# not needed when called in YaST as it is already initialized
LocaleSorter.init_locale unless defined?(Yast)

puts ARGV.sort(&LocaleSorter::SORTER).inspect
