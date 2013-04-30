require "lldp"


class Link
  attr_reader :dpid1
  attr_reader :dpid2
  attr_reader :port1
  attr_reader :port2
  attr_reader :cost

  def dump
    puts "Link.init(dpid1:#{@dpid1}, dpid2:#{@dpid2}, port1:#{@port1}, port2:#{@port2})"
  end

  def initialize dpid, packet_in
    lldp = Lldp.read( packet_in.data )
    @dpid1 = lldp.dpid
    @dpid2 = dpid
    @port1 = lldp.port_number
    @port2 = packet_in.in_port
    @cost = 10 # default link cost
  end

  def == other
    ( @dpid1 == other.dpid1 ) and
      ( @dpid2 == other.dpid2 ) and
      ( @port1 == other.port1 ) and
      ( @port2 == other.port2 )
  end


  def <=> other
    to_s <=> other.to_s
  end


  def to_s
    format "%#x (port %d) <-> %#x (port %d)", dpid1, port1, dpid2, port2
  end


  def has? dpid, port
    ( ( @dpid1 == dpid ) and ( @port1 == port ) ) or
      ( ( @dpid2 == dpid ) and ( @port2 == port ) )
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
