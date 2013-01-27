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
require "router-utils"
require "segment"
require "nat-table"
require "yaml"

class P2PSrcDstNatSwitch < Controller
  include RouterUtils
  add_timer_event :age_arp_table, 5, :periodic

  def start
    info "[P2PSrcDstNatSwitch::start]"

    @arp_table = ARPTable.new
    @switches = []

    conf_data = YAML.load_file("p2psdnatswitch.conf.yml")
    @segments = Segments.new(conf_data[:segment])
    @nat_table = NatTable.new(conf_data[:nat_table])

    #debug
    @arp_table.dump
    @segments.dump
    @nat_table.dump
  end


  def features_reply(datapath_id, message)
    info "[P2PSrcDstNatSwitch::features_reply] Datapath ID: #{ datapath_id.to_hex }"

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
    info "[P2PSrcDstNatSwitch::packet_in]"

    if to_me?(message)
      if message.arp_request?
        puts "packet_in: arp_request"
        handle_arp_request datapath_id, message
      elsif message.arp_reply?
        puts "packet_in: arp_reply"
        handle_arp_reply message
      elsif message.ipv4?
        puts "packet_in: ipv4"
        handle_ipv4 datapath_id, message
      else
        puts "packet_in: no_op"
        # noop
      end
    else
      puts "packet_in: NOT to_me?"
      # forwarding local
      handle_switched_traffic datapath_id, message
    end
  end


  def switch_ready(datapath_id)
    info "[P2PSrcDstNatSwitch::switch_ready]"

    @switches << datapath_id.to_hex
    info "switch_readh: Switch #{ datapath_id.to_hex } is UP"
    send_message datapath_id, FeaturesRequest.new
  end


  def switch_disconnected(datapath_id)
    info "[P2PSrcDstNatSwitch::switch_disconnected]"

    @switches -= [datapath_id.to_hex]
    info "switch_disconnected: Switch #{ datapath_id.to_hex } is DOWN"
  end


  private


  def handle_arp_request(dpid, message)
    info "[P2PSrcDstNatSwitch::handle_arp_request]"

    port = message.in_port
    daddr = message.arp_tpa
    segment = segment_name_of port
    nat_record = @nat_table.find_by_segment_and_vipaddr(segment, daddr)

    puts "handle_arp_request: port:#{ port }, daddr:#{ daddr }"

    if nat_record
      puts "handle_arp_request: #{ nat_record[:local].dump }"
      arp_reply = create_arp_reply_from message, nat_record[:local].virt_hwaddr
      packet_out dpid, arp_reply, SendOutPort.new(port)
    else
      puts "handle_arp_request: not found nat_record"
      handle_switched_traffic dpid, message
    end
  end


  def handle_arp_reply(message)
    info "[P2PSrcDstNatSwitch::handle_arp_reply]"
    segment = segment_name_of message.in_port
    @arp_table.update(
      segment, message.arp_spa, message.arp_sha, message.in_port)
  end


  def handle_ipv4(dpid, message)
    info "[P2PSrcDstNatSwitch::handle_ipv4]"

    segment = segment_name_of message.in_port
    puts "handle_ipv4: #{segment} from #{message.ipv4_saddr} to #{message.ipv4_daddr}"
    nat_record = @nat_table.find_by_segment_and_vipaddr(segment, message.ipv4_daddr)

    if nat_record
      nrc = nat_record[:counter]

      # to get real hwaddr and port (counter/real)
      arp_entry = @arp_table.lookup_by_segment_and_ipaddr(nrc.segment, nrc.real_ipaddr)

      if arp_entry
        actions = [
          SetEthSrcAddr.new(nrc.virt_hwaddr.to_s),
          SetEthDstAddr.new(arp_entry.hwaddr.to_s),
          SetIpSrcAddr.new(nrc.virt_ipaddr.to_s),
          SetIpDstAddr.new(nrc.real_ipaddr.to_s),
          SendOutPort.new(arp_entry.port)
        ]
        flow_mod dpid, message, actions
        packet_out dpid, message.data, actions
      else
        # handle_unresolved_packet
        handle_unresolved_packet dpid, message, nrc, nrc.real_ipaddr
      end
    else
      # no_op
      puts "handle_unresolved_packet: __TBD__"
    end
  end


  def handle_unresolved_packet(dpid, message, nat_entry, ipaddr)
    info "[P2PSrcDstNatSwitch::handle_unresolved_packet]"

    arp_request = create_arp_request_from nat_entry, ipaddr
    flood_to_segment dpid, arp_request, nat_entry.segment
  end


  def handle_switched_traffic(datapath_id, message)
    info "[P2PSrcDstNatSwitch::handle_switched_traffic]"

    segment = segment_name_of message.in_port
    if message.arp?
      @arp_table.update(
        segment, message.arp_spa, message.arp_sha, message.in_port)
    elsif message.ipv4?
      @arp_table.update(
        segment, message.ipv4_saddr, message.macsa, message.in_port)
    end

    # debug
    @arp_table.dump

    arp_entry = @arp_table.lookup_by_segment_and_hwaddr(segment, message.macda)
    if arp_entry
      flow_mod datapath_id, message, SendOutPort.new(arp_entry.port)
      packet_out datapath_id, message.data, SendOutPort.new(arp_entry.port)
    else
      # Broadcast, Unknown Unicast
      flood_to_segment(
        datapath_id,
        message.data,
        segment_name_of(message.in_port),
        message.in_port
      )
    end
  end


  def segment_name_of(port_number)
    @segments.include(@port_name_of[port_number])
  end


  def to_me?(message)
    segment = segment_name_of message.in_port
    puts "to_me?: #{segment}/#{message.macda}"
    nat_record = @nat_table.find_by_segment_and_vhwaddr(segment, message.macda)

    (message.macda.broadcast? || nat_record) ? true : nil
  end


  def age_arp_table
    @arp_table.age
  end


  def flow_mod(datapath_id, message, action)
    info "[P2PSrcDstNatSwitch::flow_mod]"

    send_flow_mod_add(
      datapath_id,
      :match => ExactMatch.from(message),
      :actions => action
    )
  end


  def packet_out(datapath_id, packet, action)
    info "[P2PSrcDstNatSwitch::packet_out]"

    send_packet_out(
      datapath_id,
      :data => packet,
      :actions => action,
      :zero_padding => true
    )
  end

  def flood_to_segment(datapath_id, data, segment_name, in_port = nil)
    info "[P2PSrcDstNatSwitch::flood_to_segment]"

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
      info "P2PSrcDstNatSwitch: not found a segment that has port:#{ in_port }"
    end
  end

end
