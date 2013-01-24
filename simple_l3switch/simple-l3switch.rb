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
require "interface"
require "router-utils"
require "routing-table"
require "segment"


class SimpleL3Switch < Controller
  include RouterUtils
  add_timer_event :age_arp_table, 5, :periodic


  def start
    info "[SimpleL3Switch::start]"

    @arp_table = ARPTable.new
    @switches = []

    load "simple_l3switch.conf"
    @segments = Segments.new($segment)
    @interfaces = Interfaces.new($interface)
    @routing_table = RoutingTable.new($route)

    # debug
    @arp_table.dump
    @segments.dump
    @interfaces.dump
  end


  def features_reply(datapath_id, message)
    info "[SimpleL3Switch::features_reply] Datapath ID: #{ datapath_id.to_hex }"

    @port_name_of = {}
    @port_number_of = {}
    message.ports.each do |each|
      # debug
      puts "Port no: #{ each.number }"
      puts "  Hardware address: #{ each.hw_addr.to_s }"
      puts "  Port name: #{ each.name }"

      @port_name_of[each.number] = each.name
      @port_number_of[each.name] = each.number
    end
  end

  def packet_in(datapath_id, message)
    puts "---------"
    info "[SimpleL3Switch::packet_in]"

    if to_me?(message)
      if message.arp_request?
        handle_arp_request datapath_id, message
      elsif message.arp_reply?
        handle_arp_reply message
      elsif message.ipv4?
        handle_ipv4 datapath_id, message
      else
        # noop.
      end
    else
      # forwarding local
      handle_switched_traffic datapath_id, message
    end
  end


  def switch_ready(datapath_id)
    info "[SimpleL3Switch::switch_ready]"

    @switches << datapath_id.to_hex
    info "switch_readh: Switch #{ datapath_id.to_hex } is UP"
    send_message datapath_id, FeaturesRequest.new
  end


  def switch_disconnected(datapath_id)
    info "[SimpleL3Switch::switch_disconnected]"

    @switches -= [datapath_id.to_hex]
    info "switch_disconnected: Switch #{ datapath_id.to_hex } is DOWN"
  end


  private


  def handle_arp_request(dpid, message)
    info "[SimpleL3Switch::handle_arp_request]"

    port = message.in_port
    daddr = message.arp_tpa
    interface = @interfaces.find_by_ipaddr(daddr)

    if interface
      info "handle_arp_request: port:#{ port }, daddr:#{ daddr }, interface:#{ interface.segment }"
      arp_reply = create_arp_reply_from message, interface.hwaddr
      packet_out dpid, arp_reply, SendOutPort.new(port)
    else
      handle_switched_traffic dpid, message
    end
  end


  def handle_arp_reply(message)
    info "[SimpleL3Switch::handle_arp_reply]"
    @arp_table.update message.in_port, message.arp_spa, message.arp_sha
  end


  def handle_ipv4(dpid, message)
    info "[SimpleL3Switch::handle_ipv4]"

    if should_forward?(message)
      forward dpid, message
    elsif message.icmpv4_echo_request?
      handle_icmpv4_echo_request dpid, message
    else
      # noop.
    end
  end


  def should_forward?(message)
    info "[SimpleL3Switch::should_forward?]"
    not @interfaces.find_by_ipaddr(message.ipv4_daddr)
  end


  def handle_icmpv4_echo_request(dpid, message)
    info "[SimpleL3Switch::handle_icmpv4_echo_request]"

    interface = @interfaces.find_by_hwaddr(message.macda)
    saddr = message.ipv4_saddr.value
    arp_entry = @arp_table.lookup_by_ipaddr(saddr)
    if arp_entry
      icmpv4_reply = create_icmpv4_reply arp_entry, interface, message
      packet_out dpid, icmpv4_reply, SendOutPort.new(arp_entry.port)
    else
      handle_unresolved_packet dpid, message, interface, saddr
    end
  end


  def forward(dpid, message)
    info "[SimpleL3Switch::forward]"

    next_hop = resolve_next_hop(message.ipv4_daddr)

    interface = @interfaces.find_by_prefix(next_hop)
    if not interface
      info "forward: not found interface for #{ next_hop }"
      return
    end
    puts "forward: nexthop:#{ next_hop.to_s }, interface:#{ interface.segment }"

    arp_entry = @arp_table.lookup_by_ipaddr(next_hop)
    if arp_entry
      puts "forward: found arp entry"
      macsa = interface.hwaddr
      macda = arp_entry.hwaddr
      port = arp_entry.port
      puts "forward: arp_request: #{ macsa }->#{ macda } (#{ @port_name_of[port] })"

      action = create_action_from macsa, macda, port
      flow_mod dpid, message, action
      packet_out dpid, message.data, action
    else
      puts "forward: not found arp entry: handle_unresolved_packet"
      handle_unresolved_packet dpid, message, interface, next_hop
    end
  end


  def resolve_next_hop(daddr)
    interface = @interfaces.find_by_prefix(daddr.value)
    if interface
      daddr.value
    else
      @routing_table.lookup(daddr.value)
    end
  end


  def handle_unresolved_packet(dpid, message, interface, ipaddr)
    info "[SimpleL3Switch::handle_unresolved_packet]"

    arp_request = create_arp_request_from interface, ipaddr
    flood_to_segment dpid, arp_request, interface.segment
  end


  def create_action_from(macsa, macda, port)
    info "[SimpleL3Switch::create_action_from]: #{ macsa }->#{ macda } (#{ @port_name_of[port] })"
    [
      SetEthSrcAddr.new(macsa.to_s),
      SetEthDstAddr.new(macda.to_s),
      SendOutPort.new(port)
    ]
  end


  def handle_switched_traffic(datapath_id, message)
    info "[SimpleL3Switch::handle_switched_traffic]"

    if message.arp?
      @arp_table.update message.in_port, message.arp_spa, message.arp_sha
    elsif message.ipv4?
      @arp_table.update message.in_port, message.ipv4_saddr, message.macsa
    end

    # debug
    @arp_table.dump

    arp_entry = @arp_table.lookup_by_hwaddr(message.macda)
    if arp_entry
      flow_mod datapath_id, message, SendOutPort.new(arp_entry.port)
      packet_out datapath_id, message.data, SendOutPort.new(arp_entry.port)
    else
      # Broadcast, Unknown Unicast
      flood_to_segment(
        datapath_id,
        message.data,
        @segments.include(@port_name_of[message.in_port]),
        message.in_port
      )
    end
  end


  def to_me?(message)
    if message.macda.broadcast? or
        @interfaces.find_by_hwaddr(message.macda)
      return true
    end
  end


  def age_arp_table
    @arp_table.age
  end


  def flow_mod(datapath_id, message, action)
    info "[SimpleL3Switch::flow_mod]"

    send_flow_mod_add(
      datapath_id,
      :match => ExactMatch.from(message),
      :actions => action
    )
  end


  def packet_out(datapath_id, packet, action)
    info "[SimpleL3Switch::packet_out]"

    send_packet_out(
      datapath_id,
      :data => packet,
      :actions => action,
      :zero_padding => true
    )
  end

  def flood_to_segment(datapath_id, data, segment_name, in_port = nil)
    info "[SimpleL3Switch::flood_to_segment]"

    if segment_name
      port_names = @segments.port_name_list_of(segment_name).dup
      puts "flood_to_segment: port_names(A): #{ port_names.join(',') }"

      port_names.delete(@port_name_of[in_port])
      puts "flood_to_segment: port_names(B): #{ port_names.join(',') }"

      actions = []
      port_names.each do |each|
        actions << SendOutPort.new(@port_number_of[each])
      end

      send_packet_out(
        datapath_id,
        :data => data,
        :actions => actions,
        :zero_padding => true
      )
    else
      info "SimpleL3Switch: not found a segment that has port:#{ in_port }"
    end
  end


end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
