#
# ARP processing routines
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


class ARPEntry
  include Trema::Logger

  attr_reader :segment
  attr_reader :ipaddr
  attr_reader :port
  attr_reader :hwaddr
  attr_writer :age_max


  def initialize(segment, ipaddr, hwaddr, port, age_max)
    @segment = segment
    @ipaddr = IPAddr.new(ipaddr)
    @hwaddr = Mac.new(hwaddr)
    @port = port
    @age_max = age_max
    @last_updated = Time.now
    info "[ARPEntry::initialize] New entry: MAC addr=#{ @hwaddr.to_s }, port=#{ @port }"
  end


  def update(port)
    @port = port
    @last_updated = Time.now
    info "[ARPEntry::update] Update entry: MAC addr=#{ @hwaddr.to_s }, port=#{ @port }"
  end


  def aged_out?
    aged_out = Time.now - @last_updated > @age_max
    info "[ARPEntry::aged_out?] Age out: An ARP entry (MAC address = #{ @hwaddr.to_s }, port number = #{ @port }) has been aged-out" if aged_out
    aged_out
  end


  def dump
    puts "#{@segment}, #{@ipaddr}, #{@hwaddr}, #{@port}, #{@last_updated}"
  end


end


class ARPTable
  include Trema::Logger

  DEFAULT_AGE_MAX = 300

  def initialize
    info "[ARPTable::initialize]"
    @db = []
  end

  def update(segment, ipaddr, hwaddr, port)
    info "[ARPTable::update] port=#{ port }, ipaddr=#{ ipaddr.to_s }, hwaddr=#{ hwaddr.to_s }"

    entry = lookup_by_segment_and_ipaddr(segment, ipaddr)
    if entry
      puts "update: find entry"
      entry.update(port)
    else
      puts "update: not found, and generate new entry"
      new_entry = ARPEntry.new(
        segment, ipaddr.to_s, hwaddr.to_s, port, DEFAULT_AGE_MAX)
      @db << new_entry
    end
  end


  def lookup_by_segment_and_ipaddr(segment, ipaddr)
    info "[ARPTable::lookup_by_segment_and_ipaddr]"
    puts "lookup_by_segment_and_ipaddr: #{segment}, #{ipaddr}"

    @db.find do |each|
      each.ipaddr.to_s == ipaddr.to_s && each.segment == segment
    end
  end


  def lookup_by_segment_and_hwaddr(segment, hwaddr)
    info "[ARPTable::lookup_by_segment_and_hwaddr]"
    puts "lookup_by_segment_and_hwaddr: #{segment}, #{hwaddr}"

    @db.find do |each|
      each.hwaddr == hwaddr && each.segment == segment
    end
  end


  def age
    @db.delete_if { |each| each.aged_out? }
  end


  def dump
    puts "[ARPTable::dump]"
    @db.each { |each| each.dump }
  end


end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
