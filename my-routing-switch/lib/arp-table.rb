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
  include Trema::DefaultLogger

  attr_reader :dpid
  attr_reader :port
  attr_reader :hwaddr
  attr_writer :age_max


  def initialize(dpid, port, hwaddr, age_max)
    @dpid = dpid
    @port = port
    @hwaddr = hwaddr
    @age_max = age_max
    @last_updated = Time.now
    info "[ARPEntry::initialize] New entry: DPID=#{ @dpid.to_hex }, MAC addr=#{ @hwaddr.to_s }, port=#{ @port }"
  end


  def update(dpid, port, hwaddr)
    @dpid = dpid
    @port = port
    @hwaddr = hwaddr
    @last_updated = Time.now
    info "[ARPEntry::update] Update entry: DPID=#{ @dpid }, MAC addr=#{ @hwaddr.to_s }, port=#{ @port }"
  end


  def aged_out?
    aged_out = Time.now - @last_updated > @age_max
    info "[ARPEntry::aged_out?] Age out: An ARP entry (DPID=#{ @dpid }, MAC address = #{ @hwaddr.to_s }, port = #{ @port }) has been aged-out" if aged_out
    aged_out
  end
end


class ARPTable
  include Trema::DefaultLogger

  DEFAULT_AGE_MAX = 300

  def initialize
    info "[ARPTable::initialize]"
    @db = {}
  end


  def update(dpid, port, ipaddr, hwaddr)
    info "[ARPTable::update] DPID=#{ dpid }, port=#{ port }, ipaddr=#{ ipaddr.to_s }, hwaddr=#{ hwaddr.to_s }"

    entry = @db[ipaddr.to_s]
    if entry
      entry.update(dpid, port, hwaddr)
    else
      new_entry = ARPEntry.new(dpid, port, hwaddr, DEFAULT_AGE_MAX)
      @db[ipaddr.to_s] = new_entry
    end
  end


  def lookup_by_ipaddr(ipaddr)
    @db[ipaddr.to_s]
  end


  def lookup_by_hwaddr(hwaddr)
    @db.each_value { |each| return each if each.hwaddr == hwaddr }
    nil
  end


  def age
    @db.delete_if { |ipaddr, entry| entry.aged_out? }
  end


  def dump
    puts "[ARPTable::dump]"

    @db.each do |ipaddr, entry|
      puts "#{ ipaddr.to_s } > #{ entry.dpid.to_hex }, #{ entry.port }, #{ entry.hwaddr.to_s }"
    end
  end

end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
