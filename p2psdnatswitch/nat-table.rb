#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

class NatEntry
  attr_reader :segment
  attr_reader :real_ipaddr
  attr_reader :virt_ipaddr
  attr_reader :virt_hwaddr


  def initialize(options)
    @segment = options["segment"]
    @real_ipaddr = IPAddr.new(options["real"]["ipaddr"])
    @virt_ipaddr = IPAddr.new(options["virtual"]["ipaddr"])
    @virt_hwaddr = Mac.new(options["virtual"]["hwaddr"])
  end


  def dump
    puts "#{@segment} real=#{@real_ipaddr} virt=#{@virt_ipaddr}/#{@virt_hwaddr}"
  end


  # alias
  def hwaddr
    @virt_hwaddr
  end


  # alias
  def ipaddr
    @virt_ipaddr
  end


end

class NatTable

  def initialize(options)
    @table = []
    options.each do |each|
      lhs = NatEntry.new(each["lhs"])
      rhs = NatEntry.new(each["rhs"])
      @table << { :lhs => lhs, :rhs => rhs }
    end
  end


  def find_by_segment_and_vipaddr(segment, ipaddr)
    puts "find_by_segment_and_vipaddr: #{ segment }, #{ ipaddr }"

    local = counter = nil
    @table.each do |each|
      if each[:lhs].virt_ipaddr == ipaddr && each[:lhs].segment == segment
        local = each[:lhs]
        counter = each[:rhs]
        break
      elsif each[:rhs].virt_ipaddr == ipaddr && each[:rhs].segment == segment
        local = each[:rhs]
        counter = each[:lhs]
        break
      end
    end

    if local || counter
      puts "find_by_segment_and_vipaddr: FOUND"
      { :local => local, :counter => counter }
    else
      # not found
      puts "find_by_segment_and_vipaddr: NOT FOUND"
      nil
    end
  end


  def find_by_segment_and_vhwaddr(segment, hwaddr)
    puts "find_by_segment_and_vhwaddr: #{ segment }, #{ hwaddr }"

    local = counter = nil
    @table.each do |each|
      if each[:lhs].virt_hwaddr == hwaddr && each[:lhs].segment == segment
        local = each[:lhs]
        counter = each[:rhs]
        break
      elsif each[:rhs].virt_hwaddr == hwaddr && each[:rhs].segment == segment
        local = each[:rhs]
        counter = each[:lhs]
        break
      end
    end

    if local || counter
      puts "find_by_segment_and_vhwaddr: FOUND"
      { :local => local, :counter => counter }
    else
      puts "find_by_segment_and_vhwaddr: NOT FOUND"
      # not found
      nil
    end
  end


  def dump
    @table.each do |each|
      puts "- - - - -"
      each[:lhs].dump
      each[:rhs].dump
    end
    puts "- - - - -"
  end


end
