
require 'test/unit'
require 'DataTable'
require 'SudokuTable'

class Tester < Test::Unit::TestCase
  
  def test_datatable
    dt = DataTable.new(3,3);
    dt.data = [1,2,3,4,5,6,7,8,9];
    assert(dt.get(0,0) == 1);
    assert(dt.get(2,1) == 8, "9 != #{dt.get(2,1)}");
    a = dt.get(0,nil);
    3.times do |i| 
      assert(a[i] == i+1, "#{i+1} != #{a[i]} in #{a.to_s}");
    end
    a = dt.get(nil,0);
    3.times do |i|
      assert(a[i] == 3*(i+1)-2, "#{a.to_s}");
    end
    dt2 = dt.cells(0,2,0,2);
    assert(dt2.get(0,0) == 1)
    assert(dt2.get(0,1) == 2)
    assert(dt2.get(0,1) == 2)   
    #dt.get(3,3);
    dt2.set('a',0,0);
    assert(dt2.get(0,0) == 'a');
    dt2.set(['b','c'],0,nil)
    dt2.each {|d| puts d;}
    assert(dt2.get(0,0) == 'b' && dt2.get(0,1) == 'c')
  end   
  
  def test_double_pair
    c = SCell.new(SudokuTable.new,0)
    dp = DoublePair.new(c)
    assert(c == dp.cell1)
    dp.cell2 = c
    assert(c == dp.cell2, "#{dp.methods.join(',')}")
  end
  
  def test_scell
    c = SCell.new(SudokuTable.new,[0,0])
    c.clear(1);
    can = c.candidates();
    assert(can.size == 8);
    p can.to_s
    assert(can[7] == 9)
    1.upto(8) do |i| assert(can[i-1] == i+1, "#{i} == #{can[i-1]}") end
    2.upto(9) do |i| assert(c.possible?(i) == true) end
    #p c.to_s
    assert(c.possible?(1) == false);
    c.assign(9);
    #p c.to_s
    1.upto(8) do |i| assert(c.possible?(i) == false) end
#    c = SCell.new
#    c.assign_hypothetical(1);
#    assert(c.value == 1);
#    assert(c.hypothetical?)
#    c.clear(1);
#    assert(c.invalid_hypothetical?)
  end  
  
  def test_sudoku1
    tc = "9"[0].to_i - "0"[0].to_i
    assert(tc == 9, "#{tc}")
    s = SudokuTable.new
    c = s.get(0,0)
    c.assign(1);
    assert(s.get(0,0).value == 1, "#{s.get(0,0)} != 1")
    s.assert(c);
    s.touch(c) do |e, cell| e.each {|i| assert(i.possible?(1) == false, "#{i}") unless i == cell} end
    s.assign(0,1,2);
    s.assert(s.get(0,1))
    assert(s.get(0,2).possible?(2) == false, "assign failed")
    s.touch(s.get(0,1)) do |e, cell| e.each {|i| assert(i != cell && i.possible?(2) == false, "#{i},#{i.pos()}, cell #{cell.pos()}") unless i == cell} end
    3.upto(9) do |i| assert(s.get(0,3).possible?(i) == true) end
    [1,2].each do |i| assert(s.get(0,3).possible?(i) == false) end  
  end
  
  def no_test_sudoku2
    s = SudokuTable.new
    s.init_from_strings(["004000918","000400000","100200300","807620000","031000650","000037802","003004005","000002000","562000100"])
    v = s.solve_all_via_asserts()
    v = s.solve_via_exclusion()
    p "sudoku2: " + s.to_html
    assert(v != nil)
    p "Sudoku 2 Solved = " + v.join(",")
  end
  
  def no_test_sudoku3
    s = SudokuTable.new
    s.init_from_strings(["160372095","000469000","007185360","800600050","703204986","040000003","071040629","000921030","200706041"])
    p s.to_html
    solution = s.solve_all_via_asserts()
    assert(solution == nil)
    solution = s.solve_via_exclusion()
    assert(solution != nil)
    p "Solution: #{solution}"
    p s.to_html
      
    p "Solution starting from: #{solution[0].pos_to_s} (#{solution[0].value})"
    solution[1].each {|c| p "#{c.pos_to_s}: #{c.value}" }
#    p s.to_s
    p s.to_html
  end

  def test_sudoku4
    s = SudokuTable.new
    s.init_from_strings(["004000918","000400000","100200300","807620000","031000650","000037802","003004005","000002000","562000100"])
    p "sudoku4 - before: " + s.to_html
    s.solve()
    p "sudoku4 - after: " + s.to_html
    p "sudoku4: " + s.events_to_html
  end

  def test_select
    a = [[1,2,3],[3,4,5],[5,6,7]]
    v = a.select {|e| e.select {|i| i == 3}.empty?() == false}
    assert(v.size() == 2, "select error: #{v.join(',')}")
  end
  
  def test_sudoku_diabolical_231
    s = SudokuTable.new
    s.init_from_strings(["004501900","020080030","600000005","008706300","050000090","003408500","300000009","080070060","002805100"])
    s.solve()
    p "s231 - after: " + s.to_html
    p "s231: " + s.events_to_html
  end
end