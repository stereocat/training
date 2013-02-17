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

class PbrLbTableEntry
  attr_reader :ipaddr
  attr_reader :tcp_port

  def initialize(options)
    @ipaddr = IPAddr.new(options[:ipaddr])
    @tcp_port = options[:tcp_port]
  end

end


class PbrLbTable
  attr_reader :vserver
  attr_reader :rservers
  attr_reader :dsr

  def initialize(options)
    @vserver = PbrLbTableEntry.new(options[:vserver])

    @rservers = []
    options[:rservers].each do |each|
      @rservers << PbrLbTableEntry.new(each)
    end

    @dsr = true if options[:dsr]
  end


  def balance_rserver(tcp_src_port)
    puts "[PbrLbTable::balance_rserver #{tcp_src_port} -> Svr #{tcp_src_port %@rservers.length}]"

    @rservers[tcp_src_port % @rservers.length]
  end


  def dsr?
    @dsr
  end

  def dump
    puts "[PbrLbTable::dump]"

    puts "vserver: #{@vserver.ipaddr}, tcp/#{@vserver.tcp_port}"
    @rservers.each do |each|
      puts "rserver: #{each.ipaddr}, tcp/#{each.tcp_port}"
    end
    puts "dsr: #{@dsr}"
  end

end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
