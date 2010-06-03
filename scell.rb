
class CellEvent
  SOLVED = 'SOLVED'
  PAIR = 'PAIR'
  ASSIGNED = 'ASSIGNED' 
  
  attr_reader :cell, :type, :data
  attr :state, true
    
  def initialize(c,t,d = nil)
    @cell = c
    @type = t
    @data = d
  end
  
  def to_s
    return "#{self.type}, #{self.cell.pos_to_s}: #{self.data}"
  end
end

class SCell
  SIZE = 9
  POSSIBLE = 0;
  IMPOSSIBLE = 1;
#  NO_HYPOTHETICAL = 0;   

  @val
  @table
  attr_reader :b,:pos,:r,:c
#  @hypo_val = NO_HYPOTHETICAL;
  
  def initialize(table, pos) 
    @b = BitVector.new(SIZE)
    @table = table
#    @hypo_val = NO_HYPOTHETICAL;
    @pos = pos
    @r = pos[0]
    @c = pos[1]
  end
  
  def <=>(o)
    if value() != nil and o.value() != nil
      return value() <=> o.value()
    end
    if value() == nil and o.value() == nil
      return candidates() && o.candidates()
    end
    return false
  end
  
  def to_s
    #p value()
    return "#{@val}" if @val != nil
    return "?" + candidates().join("/")
  end
  
  def pos_to_s
    return pos().join(",")
  end
  
#  def to_bits() 
#    s = "";
#    SIZE.times {|i| s.concat @b[i].to_s}
#    return s
#  end

  def each()
    SIZE.times {|i| yield(@b[i])}
  end
  
  def clear(nums)
    if nums.is_a? Array
      for n in nums do _clear(n) end
    else
      _clear(nums)
    end
  end    

  def _clear(num)
    raise "Clear value out of bounds: #{num}" if num > SIZE
    @b[num-1] = IMPOSSIBLE
    _update()    
  end  
  def possible?(num)
    v = self.value() 
    return v == num if v != nil
    return @b[num-1] == POSSIBLE
  end
  
#  def hypothetical?
#    return @hypo_val != NO_HYPOTHETICAL;
#  end
  
#  def invalid_hypothetical?
#    return true if @b[@hypo_val-1] == IMPOSSIBLE
#  end 
  
  def assign(num)
    #p num 
    @val = num
    SIZE.times do |i| @b[i] = IMPOSSIBLE unless i == num-1 end
    @table.notify(CellEvent.new(self,CellEvent::ASSIGNED, num))
  end
  
  def to_i
    return pos.hash
  end
  
#  def assign_hypothetical(num)
#    @hypo_val = num;
#  end
  
  def value()
    return @val
  end
  
  def _update()
    return @val if @val != nil
    v = nil
    SIZE.times do |i| 
      if @b[i] == POSSIBLE
        if v == nil
          v = i+1
        else
          return nil
        end
      end
    end
    @val = v
    @table.notify(CellEvent.new(self,CellEvent::SOLVED,v))
    #p "#{self.pos_to_s()} value = #{v}"
    return v
  end
  
  def candidates()
    return Array.new if value() != nil
    a = Array.new;
    SIZE.times do |i| 
      if @b[i] == POSSIBLE
        a.push(i+1);
      end
    end
    return a
  end
end

