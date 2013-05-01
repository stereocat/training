$LOAD_PATH.unshift File.expand_path( File.join File.dirname( __FILE__ ), "lib" )

require "rubygems"
require "bundler/setup"

require "command-line"
require "topology"
require "trema"
require "trema-extensions/port"

require "arp-table"

class MyRoutingSwitch < Controller
  periodic_timer_event :age_arp_table, 10
  periodic_timer_event :flood_lldp_frames, 10
#  periodic_timer_event :check, 10


  def start
    @command_line = CommandLine.new
    @command_line.parse( ARGV.dup )
    @topology = Topology.new( @command_line.view )
    @arp_table = ARPTable.new
    @switch_ready = {}
  end


  def switch_ready dpid
    send_message dpid, FeaturesRequest.new
    @switch_ready[dpid] = true
  end


  def features_reply dpid, features_reply
    features_reply.physical_ports.select( &:up? ).each do | each |
      @topology.add_port dpid, each
    end
  end


  def switch_disconnected dpid
    @topology.delete_switch dpid
    @switch_ready.delete(dpid)
  end


  def port_status dpid, port_status
    updated_port = port_status.port
    return if updated_port.local?
    @topology.update_port dpid, updated_port
  end


  def packet_in dpid, packet_in
    unless @switch_ready[dpid]
      # ignore packet_in until complete features request/reply
      warn "Switch:#{dpid} does not ready"
      return
    end

    if packet_in.lldp?
      @topology.add_link_by dpid, packet_in
    elsif packet_in.arp_request?
      handle_arp_request dpid, packet_in
    elsif packet_in.arp_reply?
      handle_arp_reply dpid, packet_in
    elsif packet_in.ipv4?
      handle_ipv4 dpid, packet_in
    else
      # noop
    end
  end


  ##############################################################################
  private
  ##############################################################################

  def update_arp_table dpid, packet_in
    if packet_in.arp?
      @arp_table.update dpid, packet_in.in_port, packet_in.arp_spa, packet_in.arp_sha
    elsif packet_in.ipv4?
      @arp_table.update dpid, packet_in.in_port, packet_in.ipv4_saddr, packet_in.macsa
    end

    # @arp_table.dump
  end

  def handle_arp_request dpid, packet_in
    puts "[MyRoutingSwitch::handle_arp_request]"

    update_arp_table dpid, packet_in

    port = packet_in.in_port
    daddr = packet_in.arp_tpa
    arp_entry = @arp_table.lookup_by_ipaddr(daddr)

    puts "arp request: #{packet_in.arp_spa} -> #{daddr}"

    if arp_entry
      # if found, path through the frame
      puts "FOUND ARP_ENTRY action: dpid:#{arp_entry.dpid}, SendOutPort: #{arp_entry.port}"
      packet_out arp_entry.dpid, packet_in.data, SendOutPort.new(arp_entry.port)
    else
      # if not found, flood to endpoints and search destination
      endpoint_ports = @topology.get_endpoint_ports.dup
      if endpoint_ports
        endpoint_ports[dpid].delete(port)
        endpoint_ports.each_pair do |each_dpid, port_numbers|
          actions = []
          port_numbers.each do |each|
            puts "FLOOD: action: dpid: #{each_dpid}, SendOutPort: #{each}"
            actions << SendOutPort.new(each)
          end
          packet_out each_dpid, packet_in.data, actions
        end
      else
        warn "NOT FOUND: endpoint_ports"
      end
    end
  end


  def handle_arp_reply dpid, packet_in
    puts "[MyRoutingSwitch::handle_arp_reply]"

    update_arp_table dpid, packet_in

    port = packet_in.in_port
    daddr = packet_in.arp_tpa
    arp_entry = @arp_table.lookup_by_ipaddr(daddr)

    if arp_entry
      puts "action: dpid:#{arp_entry.dpid}, SendOutPort: #{arp_entry.port}"
      packet_out arp_entry.dpid, packet_in.data, SendOutPort.new(arp_entry.port)
    else
      error "NOT FOUND destination of arp_reply: #{packet_in.arp_spa}/#{packet_in.arp_sha}"
    end
  end


  def handle_ipv4 dpid, packet_in
    puts "[MyRoutingSwitch::handle_ipv4]"

    update_arp_table dpid, packet_in

    puts "IPv4: dpid:#{dpid}, port:#{packet_in.in_port}, #{packet_in.ipv4_saddr}->#{packet_in.ipv4_daddr}"

    arp_entry = @arp_table.lookup_by_ipaddr(packet_in.ipv4_daddr)
    if arp_entry
      start_dpid = dpid
      goal_dpid = arp_entry.dpid
      goal_port = arp_entry.port

      path = @topology.get_path goal_dpid, start_dpid

      now_dpid = start_dpid
      while path[now_dpid]
        next_dpid = path[now_dpid]
        link = @topology.get_link(now_dpid, next_dpid)

        puts "flow_mod: dpid:#{now_dpid}/port:#{link.port1} -> dpid:#{next_dpid}"
        flow_mod now_dpid, build_match(packet_in), SendOutPort.new(link.port1)
        now_dpid = next_dpid
      end

      # last hop
      action = SendOutPort.new(goal_port)
      flow_mod goal_dpid, build_match(packet_in), action
      packet_out goal_dpid, packet_in.data, action
    else
      warn "NOT FOUND path from #{packet_in.ipv4_saddr} to #{packet_in.ipv4_daddr}"
    end
  end


  def build_match packet_in
    Match.new(
      :dl_src => packet_in.macsa,
      :dl_dst => packet_in.macda,
      :dl_type => packet_in.eth_type,
      :nw_src => packet_in.ipv4_saddr.to_s,
      :nw_dst => packet_in.ipv4_daddr.to_s
    )
  end

  def flow_mod dpid, match, actions
    send_flow_mod_add(
      dpid,
      :match => match,
      :actions => actions
    )
  end


  def packet_out dpid, data, actions
    send_packet_out(
      dpid,
      :data => data,
      :actions => actions,
      :zero_padding => true
    )
  end


  def check
    puts "[check]"
    puts "path: #{@topology.get_path(0x4, 0x1).to_a.join(", ")}"
    puts "endpoint_ports:"
    @topology.get_endpoint_ports.each_pair do |dpid, port_numberes|
      puts "dpid: #{dpid}"
      port_numberes.each do |each|
        puts "    #{each}"
      end
    end
  end

  def flood_lldp_frames
    @topology.each_switch do | dpid, ports |
      send_lldp dpid, ports
    end
  end


  def send_lldp dpid, ports
    ports.each do | each |
      port_number = each.number
      send_packet_out(
        dpid,
        :actions => SendOutPort.new( port_number ),
        :data => lldp_binary_string( dpid, port_number )
      )
    end
  end


  def lldp_binary_string dpid, port_number
    destination_mac = @command_line.destination_mac
    if destination_mac
      Lldp.new( dpid, port_number, destination_mac.value ).to_binary
    else
      Lldp.new( dpid, port_number ).to_binary
    end
  end


  def age_arp_table
    @arp_table.age
  end


end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
