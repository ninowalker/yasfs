require 'DataTable'
require 'bitvector'
require 'scell'

class SudokuValidityError < RuntimeError
  attr_reader :array
  def initialize(array,msg)
  end
end

class DoublePair
  public
  attr_reader :a, :b
  attr :cell1, true
  attr :cell2, true
  
  def initialize(c)
    @cell1 = c
    @cell2 = nil
    cans = c.candidates()
    @a = cans[0]
    @b = cans[1]
  end
  def to_s
    return @c1.to_s
  end
end


class SudokuTable < DataTable
  DIM = 9
  @_elements = nil
  @state
  INIT = 'INIT'
  ASSERT = 'ASSERT'
  EXCLUSIVE = 'EXCLUSIVE'
  PAIRS = 'PAIRS'
  
  def initialize()
    super(DIM,DIM)
    @_event = Array.new
    @found_queue = Array.new
    0.upto(self.size()-1) do |i|
      @data[i] = SCell.new(self,[((i/DIM)).to_i,((i%DIM)).to_i]);
    end
  end
  
  def init_from_strings(strs)
    @state = INIT
    0.upto(DIM-1) do |i|
      raise "Invalid length arg: #{strs[i]}" if strs[i] == nil || strs[i].length != DIM
      0.upto(DIM-1) do |j|
        init_value(i,j,strs[i][j].to_i - "0"[0].to_i) if strs[i][j].to_i != "0"[0].to_i
      end     
    end
  end
  
  def <=>(o)
    return -1 if o.cols != self.cols
    return -2 if o.rows != self.rows
    for i in 0 .. size() - 1
      if (self.data[i] <=> o.data[i]) != 0
        return i
      end
    end
    return 0
  end
      
  def assign(r,c,val)
    get(r,c).assign(val)
  end

  def init_value(r,c,val)
    get(r,c).assign(val)
  end  

  def assert_found
    return false if @found_queue.empty?()
    while (!@found_queue.empty?())
      cell = @found_queue.shift.cell
      assert(cell)
    end
    return true
  end
  
    
  def solve()
    run = true
    while (!@found_queue.empty?())
      assert_found()
      solve_all_matched_pairs()
      solve_via_exclusion()
      solve_all_matched_pairs()
      solve_via_exclusion()
    end
  end
    
  def is_exclusive?(c,v,a)
    for i in a
      next if i == c
      return false if (i.possible?(v))  
    end
    return true
  end
  
  
  def solve_via_exclusion
    @state = EXCLUSIVE
    for e in elements()
      for c in e
        next if c.value() != nil
        for p in c.candidates()
          if is_exclusive?(c,p,e)
            c.assign(p)
            return true
          end
        end    
      end
    end
  end
  
  def exclusive_possibility?(c)
    return false if c.value() == nil
    for p in c.candidates()  
      for e in elements(c)
        if is_exclusive?(c,p,e)
          c.assign(p)
          return true
        end
      end
    end    
  end
  
  def elements(cell = nil) 
    if cell == nil 
      @_elements = data_rows() + data_cols() + sub_areas() if @_elements == nil  
      return @_elements
    end
    return [sub_area(cell.r,cell.c), get(cell.r,nil), get(nil,cell.c)] 
  end 

  def solve_all_matched_pairs()
    matched = false
    for e in elements()
      matched = true if has_matched_pairs?(e)
    end    
    return matched
  end

  def has_matched_pairs?(element)
    @state = PAIRS
    pairs = Hash.new
    unknown = Hash.new
    hit = false
    for c in element
      next if c.value != nil
      cans = c.candidates()
      unknown[c] = cans            
      if cans.size == 2
        if pairs[c.to_s] == nil
          pairs[c.to_s] = DoublePair.new(c) 
        else
          pairs[c.to_s].cell2 = c
        end
      end
    end
    pairs.each_value do |dp|
      dp.cell1
      next if dp.cell2 == nil
      unknown.each_key{|cell| cell.clear([dp.a,dp.b]) unless cell == dp.cell1 || cell == dp.cell2} 
      hit = true
    end
    return hit
  end
  
  
  def check_validity()
    for e in elements()
      check_element_validity(e)
    end
  end

  def check_element_validity(array)
    vect = BitVector.new(9)
    for a in array
      v = a.value();
      if (v != nil)
         # make sure the number is not already in the 
         raise SudokuValidityError.new(array, "Duplicate value #{v}") if vect[v-1] == 1
         vect[v-1] = 1
         next
      end
      c = a.candidates()
    end
  end
  
  def assert(cell) 
    return if cell.value() == nil
    for e in elements(cell)
      e.each {|i| i.clear(cell.value) unless i == cell }
    end
  end
  
  def sub_area(r,c)
    return cells((r/3).to_i*3,3,(c/3).to_i*3,3);
  end
  
  def sub_areas()
    a = []
    0.upto(2) do |i| 
      0.upto(2) do |j|
        a.push(sub_area((i*3)+1,(j*3)+1))
      end
    end
    @sreas = a
    return a
  end
  
  def notify(e)
    e.state = @state
    @_event.push(e)
    @found_queue.push(e) if e.type == CellEvent::SOLVED or e.type == CellEvent::ASSIGNED
    p "#{e}"
  end

  def deduce
    while (!@found_queue.isempty?())
      cell = @found_queue.shift.cell
      assert(cell)
    end
  end
  
  def events_to_html
    s = "<table>"
    for e in @_event
      s += "<tr><td>#{e.type}</td><td>#{e.cell.pos_to_s}</td><td>#{e.data}</td><td>#{e.state}</td></tr>"
    end
    s += "</table>"
  end
  
  def touch(cell)
    for e in elements(cell)
      yield(e,cell)    
    end
  end
end

