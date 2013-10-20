#
# A router implementation in Trema
#
# Copyright (C) 2013 NEC Corporation
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

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require "arp-table"
require "interface"
require "router-utils"
require "routing-table"

class SimpleFirewall < Controller
  include RouterUtils

  def start
    info "[SimpleFirewall::start]"
    load "simple_firewall.conf"
    @interfaces = Interfaces.new( $interface )
    @arp_table = ARPTable.new
    @routing_table = RoutingTable.new( $route )
  end


  def switch_ready dpid
    info "[SimpleFirewall::ready]: #{ dpid.to_hex }"
  end


  def packet_in( dpid, message )
    return if not to_me?( message )

    if message.arp_request?
      handle_arp_request dpid, message
    elsif message.arp_reply?
      handle_arp_reply message
    elsif message.ipv4?
      handle_ipv4 dpid, message
    else
      # noop.
    end
  end


  private


  def to_me?( message )
    return true if message.macda.broadcast?

    interface = @interfaces.find_by_port( message.in_port )
    if interface and interface.has?( message.macda )
      return true
    end
  end


  def handle_arp_request( dpid, message )
    port = message.in_port
    daddr = message.arp_tpa
    interface = @interfaces.find_by_port_and_ipaddr( port, daddr )
    if interface
      arp_reply = create_arp_reply_from( message, interface.hwaddr )
      packet_out dpid, arp_reply, SendOutPort.new( interface.port )
    end
  end


  def handle_arp_reply( message )
    @arp_table.update message.in_port, message.arp_spa, message.arp_sha
  end


  def filtered?( dpid, message )
    port = message.in_port
    interface = @interfaces.find_by_port( port )
    infilter = interface.infilter
    filtered = false # not filtered
    if infilter
      opts = {
        :src_ip => message.ipv4_saddr.to_s,
        :dst_ip => message.ipv4_daddr.to_s
      }
      if message.tcp?
        opts[ :protocol ] = "tcp"
        opts[ :src_port ] = message.tcp_src_port
        opts[ :dst_port ] = message.tcp_dst_port
      elsif message.udp?
        opts[ :protocol ] = "udp"
        opts[ :src_port ] = message.udp_src_port
        opts[ :dst_port ] = message.udp_dst_port
      elsif message.icmpv4?
        opts[ :protocol ] = "icmp"
      end

      ace = infilter.search_ace( opts )
      if ace
        # when found matched ace
        case ace.action
        when "permit"
          info "packet permitted # #{ _pph(opts) }"
        when "deny"
          info "packet denied (explicitly) # #{ _pph(opts) }"
          filtered = true
        end
      else
        # not found matched entry
        info "packet denied (implicitly) # #{ _pph(opts) }"
        filtered = true
      end
    end

    return filtered
  end


  def handle_ipv4( dpid, message )
    if filtered?( dpid, message )
      # if denied, drop rule send to OVS
      send_drop_flow_mod( dpid, message )
      return
    end

    # permitted or filter does not exists at interface
    if should_forward?( message )
      forward dpid, message
    elsif message.icmpv4_echo_request?
      handle_icmpv4_echo_request dpid, message
    else
      # noop.
    end
  end


  def should_forward?( message )
    # info "[SimpleFirewall::should_forward?]"
    not @interfaces.find_by_ipaddr( message.ipv4_daddr )
  end


  def handle_icmpv4_echo_request( dpid, message )
    interface = @interfaces.find_by_port( message.in_port )
    saddr = message.ipv4_saddr.value
    arp_entry = @arp_table.lookup( saddr )
    if arp_entry
      icmpv4_reply = create_icmpv4_reply( arp_entry, interface, message )
      packet_out dpid, icmpv4_reply, SendOutPort.new( interface.port )
    else
      handle_unresolved_packet dpid, message, interface, saddr
    end
  end


  def forward( dpid, message )
    # info "[SimpleFirewall::forward]"
    next_hop = resolve_next_hop( message.ipv4_daddr )

    interface = @interfaces.find_by_prefix( next_hop )
    if not interface or interface.port == message.in_port
      return
    end

    arp_entry = @arp_table.lookup( next_hop )
    if arp_entry
      macsa = interface.hwaddr
      macda = arp_entry.hwaddr
      action = create_action_from( macsa, macda, interface.port )
      flow_mod dpid, message, action
      packet_out dpid, message.data, action
    else
      handle_unresolved_packet dpid, message, interface, next_hop
    end
  end


  def resolve_next_hop( daddr )
    interface = @interfaces.find_by_prefix( daddr.value )
    if interface
      daddr.value
    else
      @routing_table.lookup( daddr.value )
    end
  end


  def flow_mod( dpid, message, action )
    send_flow_mod_add(
      dpid,
      :match => ExactMatch.from( message ),
      :actions => action
    )
  end


  def packet_out( dpid, packet, action )
    # info "[SimpleFirewall::packet_out] #{ dpid.to_hex }"
    send_packet_out(
      dpid,
      :data => packet,
      :actions => action
    )
  end


  def send_drop_flow_mod dpid, packet_in
    # info "[SimpleFirewall::send_drop_flow_mod]"
    send_flow_mod_add(
      dpid,
      :idle_timeout => 60,
      :match => srcdst_match( packet_in )
    )
  end

  def srcdst_match packet_in
    opts = {
      :dl_type => packet_in.eth_type,
      :nw_src  => packet_in.ipv4_saddr.to_s,
      :nw_dst  => packet_in.ipv4_daddr.to_s,
    }
    if packet_in.tcp?
      opts[ :nw_proto ] = 6
      opts[ :tp_src ] = packet_in.tcp_src_port
      opts[ :tp_dst ] = packet_in.tcp_dst_port
    elsif packet_in.udp?
      opts[ :nw_proto ] = 17
      opts[ :tp_src ] = packet_in.udp_src_port
      opts[ :tp_dst ] = packet_in.udp_dst_port
    elsif packet_in.icmpv4?
      opts[ :nw_proto ] = 1
    end
    Match.new opts
  end

  def handle_unresolved_packet( dpid, message, interface, ipaddr )
    info "[SimpleFirewall::handle_unresolved_packet]"
    arp_request = create_arp_request_from( interface, ipaddr )
    packet_out dpid, arp_request, SendOutPort.new( interface.port )
  end


  def create_action_from( macsa, macda, port )
    [
      SetEthSrcAddr.new( macsa ),
      SetEthDstAddr.new( macda ),
      SendOutPort.new( port )
    ]
  end

  # pretty-print of hash
  def _pph hash
    str = ""
    hash.each { | k, v | str.concat("#{k.to_s}=>#{v.to_s},") }
    return str
  end

end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
