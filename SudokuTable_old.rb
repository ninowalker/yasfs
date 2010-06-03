require 'DataTable'
require 'bitvector'
require 'scell'

class SudokuValidityError < RuntimeError
  attr_reader :array
  def initialize(array,msg)
  end
end

class SudokuTable < DataTable
  DIM = 9
  events = []
  found_queue = []
  @_elements = nil
  
  def initialize()
    super(DIM,DIM)
    0.upto(self.size()-1) do |i|
      @data[i] = SCell.new(self,[((i/DIM)).to_i,((i%DIM)).to_i]);
    end
  end
  
  def init_from_strings(strs)
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
    
  def operate(r,c) 
    cell = get(r,c);
    area = sub_area(r,c)
    row = get(r,nil)
    col = get(nil,c)
    res = []
    for a in [area, row, col]
      for i in a
        next if i == cell
        if (yield(i,cell))
          res.push(i)
        end
      end
    end
    return res if res.size > 1
    return nil
  end
  
  def assign(r,c,val)
    get(r,c).assign(val)
    assert(r,c)
  end

  def init_value(r,c,val)
    get(r,c).assign(val)
  end  
  
  def solve_all_via_asserts()
    solved = []
    for c in @data
      v = assert_one(c)
      solved += v if v != nil
    end
    return nil if solved.empty?()
    count = 0
    while (count < solved.size())
      v = assert_one(solved[count])
      solved += v if v != nil
      count += 1
    end
    return solved
  end
  
  def solve()
    solved = []
    run = true
    while (run)
      s = solve_all_via_asserts()
      solved.push(s) if s != nil
      s = solve_via_exclusion()
      solved.push(s) if s != nil
      if s == nil
        run = solve_all_matched_pairs()
      end
    end
  end
  
  def assert_one(c)
   if c.value() != nil
      p "Asserting #{c.pos_to_s}: #{c.value}"
      v = operate(c.pos[0],c.pos[1]) { |i, cell| i.value == nil && i.clear(c.value) != nil }
      return v if v != nil
    end
    return nil
  end
  
  def is_exclusive?(c,v,a)
    for i in a
      next if i == c
      return false if (i.possible?(v))  
    end
    return true
  end
  
  def solve_via_exclusion
    for c in @data
      if c.value() == nil
        p "Testing #{c.pos_to_s}: #{c.value}"
        row = c.pos[0]
        col = c.pos[1]
        for p in c.candidates()  
        # or is_exclusive?(c,p,get(row,nil)) or is_exclusive?(c,p,get(col,nil))
          if is_exclusive?(c,p,sub_area(row,col)) or is_exclusive?(c,p,get(row,nil)) or is_exclusive?(c,p,get(col,nil))
            c.assign(p)
            return c
          end
        end
      end
    end
    return nil
  end
  
  def elements(cell = nil)
    if cell == nil 
      @_elements = data_rows() + data_cols() + sub_areas() if @_elements != nil  
     return @_elements
    end
  end 

  def solve_all_matched_pairs()
    matched = false
    for e in elements()
      matched = true if has_matched_pairs?(e)
    end    
    return matched
  end
  
  def has_matched_pairs?(element)
    pairs = []
    candidates = []
    hit = false
    for c in element
      next if c.value != nil
      cp = [c,c.candidates]
      candidates.push(cp)
      pairs.push(cp) if cp[1].size == 2
    end
    for cp in pairs
      p "Pair:  " + cp.join(" - ")
      cps = candidates.select {|cp1| cp1[0] != cp[0] and is_pair_match?(cp[1][0], cp[1][1], cp1[1]) }
      next if cps.empty?()
      p "Pairs: " + cps.join("...")
      for c in element.select{|cell| cell != cp[0] and cps.select{|i| cell == i[0] }.empty?() == true } 
        c.clear(cp[1]) 
        hit = true
      end 
    end
    return hit
  end
  
  def is_pair_match?(a,b,candidates)
    return candidates.size() == 2 && candidates.select {|e| e == a or e == b }.empty?() == false
  end
  
  def check_validity(r,c)
    operate(r,c) do |i, cell| i.clear(cell.value) unless i == cell end    
  end

  def _check_validity(array)
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
  
  def assert(r,c) 
    operate(r,c) do |i, cell| i.clear(cell.value) unless i == cell end
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
    @events.push(e)
    @found_queue.push(e) if e.type == CellEvent.SOLVED or e.type == CellEvent.ASSIGNED
  end

  def deduce
    while (!@found_queue.isempty?())
      
    end
  end
  
  def events_to_html
    s = "<table>"
    for e in @events
      s += "<tr><td>#{e.type}</td><td>#{e.cell.pos()}</td></tr>"
    end
    s += "</table>"
  end
  
end

