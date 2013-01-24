#
# A router implementation in Trema
#
# Copyright (C) 2012 NEC Corporation
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


require "arp-table"
require "routing-table"


class Interface
  attr_reader :hwaddr
  attr_reader :ipaddr
  attr_reader :masklen
  attr_reader :segment


  def initialize options
    @hwaddr = Mac.new(options[:hwaddr])
    @ipaddr = IPAddr.new(options[:ipaddr])
    @masklen = options[:masklen]
    @segment = options[:segment]
  end


  def has? mac
    mac == hwaddr
  end

end


class Interfaces

  def initialize interfaces = []
    @list = []
    interfaces.each { |each| @list << Interface.new(each) }
  end


  def find_by_hwaddr(hwaddr)
    @list.find { |each| each.has?(hwaddr) }
  end


  def find_by_segment(segment)
    @list.find { |each| each.segment == segment }
  end


  def find_by_ipaddr(ipaddr)
    @list.find { |each| each.ipaddr == ipaddr }
  end


  def find_by_prefix(ipaddr)
    @list.find do |each|
      masklen = each.masklen
      each.ipaddr.mask(masklen) == ipaddr.mask(masklen)
    end
  end


  def find_by_segment_and_ipaddr(segment, ipaddr)
    @list.find { |each| each.segment == segment && each.ipaddr == ipaddr }
  end


  def ours?(segment, macda)
    # TBD
  end


  def dump
    puts "[Interface::dump]"

    @list.each do |each|
      puts "interface: #{ each.ipaddr.to_s }/#{ each.masklen } (#{ each.segment })"
    end
  end

end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
