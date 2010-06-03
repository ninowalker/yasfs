#!/usr/bin/ruby
# bitvector.rb: simple native ruby bitvector implementation.
#
# = Summary
# This library provides a basic bitvector library implemented
# in pure ruby.  A C-based library would be faster. It was written
# in a few hours and may be prone to errors, or later relicensing.
#
#
# = LicensE
# Copyright (C) 2005 Will Drewry
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software Foundation,
#   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#

# Error class for requests outside of a valid vector size.
class BitVectorSizeExceededError < RuntimeError
end

class BitVector
  attr_reader :size
  attr_accessor :storage

  BYTE_IN_BITS = 8   # in bits
  INITIAL_VALUE = 0

  # Create a new BitVector of size N where N is the number of
  # entries which are counted starting at 0.
  def initialize(size=32)
    @size = size
    in_bytes = size / BYTE_IN_BITS
    @fixnum_bytes = 1.size
    @total_bits = (@fixnum_bytes * BYTE_IN_BITS)
    needed = in_bytes / @fixnum_bytes
    needed += 1 if size % BYTE_IN_BITS > 0
    @storage = Array.new(needed, INITIAL_VALUE)
  end

  # The bitwise OR operator allows for fast combination
  # of two bitvectors resulting in a new bitvector.
  def |(bv)
    vec = BitVector.new([bv.size, @size].max)
    vec.storage.length.times do |idx|
      vec.storage[idx] = @storage[idx].to_i | bv.storage[idx].to_i
    end
    return vec
  end

  # The bitwise AND operator allows for fast combination
  # of two bitvectors resulting in a new bitvector.
  def &(bv)
    vec = BitVector.new([bv.size, @size].max)
    vec.storage.length.times do |idx|
      vec.storage[idx] = @storage[idx].to_i & bv.storage[idx].to_i
    end
    return vec
  end

  # Basic equality test
  def ==(bv)
    return false if bv.storage.length != @storage.length
    @storage.length.times do |i|
      return false if @storage[i] != bv.storage[i]
    end
    return true
  end

  # Returns a 1 or 0 if a particular entry in the bitvector is
  # set. If a range is specified, the results will be returned in
  # an array.
  def get(offset_or_range)
    if offset_or_range.respond_to? :each
      return get_range(offset_or_range)
    else
      if offset_or_range >= @size
        raise BitVectorSizeExceededError,
          "Offset #{offset_or_range} exceeds size of bitvector."
      end
      return get_single(offset_or_range)
    end
  end 
  alias_method :[], :get

  # Sets the given offset (or offset range) to on (> 0) or off (0).
  def set(offset_or_range, value)
    if offset_or_range.respond_to? :each
      set_range(offset_or_range, value)
    else
      if offset_or_range >= @size
        raise BitVectorSizeExceededError,
          "Offset #{offset_or_range} exceeds size of bitvector."
      end
      set_single(offset_or_range, value)
    end
    nil
  end
  alias_method :[]=, :set

 private
  # Perform the simple calculation to get the storage array offset
  # and the shift argument into that Fixnum.
  def calculate_index_and_shift(offset)
    [offset / @total_bits, offset - (@total_bits * (offset / @total_bits))]
  end

  # Returns the 1 if the offset is set, or 0 otherwise.
  def get_single(offset)
    idx, shift = calculate_index_and_shift(offset)
    shifted = 1 << shift
    return 1 if (@storage[idx]  & shifted) == shifted
    return 0
  end

  # Returns an array of 1s and 0s for a range of offsets.
  def get_range(range)
    val = []
    range.each do |i|
      val << get_single(i)
    end
    return val
  end

  # Sets a range of offsets to a given value.
  def set_range(range, value)
    range.each do |i|
      set_single(i, value)
    end
  end

  # Sets a single offset on if if value > 0 or off if <= 0.
  def set_single(offset, value)
    idx, shift = calculate_index_and_shift(offset)
    shifted = 1 << shift
    # If we are turning it on, do it
    if value > 0
      @storage[idx] |= shifted
    # Else if it is already set, flip it
    else
      if (@storage[idx] & shifted) == shifted
        @storage[idx] ^= shifted
      end
    end
  end
end # BitVector

# Example usage
if __FILE__ == $0
  a = BitVector.new(65)
  b = BitVector.new(6500)
  
  p "a: setting [10,14,40,64] to 1"
  a.set([10,14,40,64], 1)
  p a[[10,14,40,64]]
  p "b: setting [10,40,100,2432,6400] to 1"
  b.set([10,40,100,2432,6400], 1)
  p b[[10,40,100,2432,6400]]
  
  print "a: "
  p a

  print "b: "
  p b

  print "AND'd: "
  anded = a & b
  p anded.get([10,14,40,64,100,2432,6400])


  print "OR'd: "
  ored = a | b
  p ored.get([10,14,40,64,100,2432,6400])

  p "a: setting [10,64] to 0"
  a.set([10,64], 0)
  print "a[10..64]: "
  p a[10..64]
end
