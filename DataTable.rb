class DataTable
  attr_writer :data;
  attr_reader :rows;
  attr_reader :cols
  
  def initialize (r,c)
    @rows = r;
    @cols = c; 
    @data = Array.new(@rows*@cols);
  end
  
  def size() 
    return @rows*@cols
  end
  
  def index(i) 
    return @data[i];
  end
  
  def pos(r,c) 
    raise IndexError, "#{r} >= rows" if (r >= @rows)
    raise IndexError, "#{c} >= cols" if (c >= @cols)
    return r*@cols + c;
  end  
  
  def get(r,c)
    #get item
    if (r != nil and c != nil) 
      return @data[pos(r,c)];
    end
    #get row
    if (r != nil and c == nil)
      a = Array.new(@cols);
      @cols.times do |cl|
        a[cl] = @data[pos(r,cl)];
      end
      return a
    end
    #get column
    if (r == nil and c != nil)
      a = Array.new(@rows);
      @rows.times do |cl|
        a[cl] = @data[pos(cl,c)];
      end
      return a
    end
  end
  
  def set(v,r,c)
    #set item
    if (r != nil and c != nil) 
      @data[pos(r,c)] = v;
    end
    #set row
    if (r != nil and c == nil)
      @cols.times do |cl|
        @data[pos(r, cl)] = v[cl];
      end
    end
    #set column
    if (r == nil and c != nil)
      @rows.times do |cl|
        @data[pos(cl, c)] = v[cl];
      end
    end
  end
  
  def cells(r,rc,c,cc)
    dt = DataTable.new(rc,cc);
    rc.times do |i|
      cc.times do |j|
        dt.set(get(r+i,c+j),i,j);
      end
    end
    return dt;
  end
  
  def data_rows()
    a = []
    0.upto(@rows-1) do |i|
      a.push(get(i,nil))
    end
    return a
  end

  def data_cols()
    a = []
    0.upto(@cols-1) do |i|
      a.push(get(nil,i))
    end
    return a
  end

  
  def each 
    @data.each { |d| yield(d) }
  end
  
  def select
    @data.select {|d| yield(d) }
  end
  
  def to_s
    s = ""
    0.upto(@rows-1) do |i|
      s += get(i,nil).join("-") + "\n"
    end
    return s
  end

  def to_html
    s = "<table>"  
    0.upto(@rows-1) do |i|
      s += "<tr><td>" + get(i,nil).join("</td><td>") + "</td></tr>"
    end
    return s + "</table>"
  end
# end class
end