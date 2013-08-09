require "rubygems"
require "pio/lldp"


class Link
  include Trema::DefaultLogger

  attr_reader :dpid1
  attr_reader :dpid2
  attr_reader :port1
  attr_reader :port2
  attr_reader :cost
  attr_writer :age_max


  def initialize dpid, packet_in, cost, age_max
    lldp = Pio::Lldp.read( packet_in.data )
    @dpid1 = lldp.dpid.to_i
    @dpid2 = dpid
    @port1 = lldp.port_number.to_i
    @port2 = packet_in.in_port
    @cost = cost
    @age_max = age_max
    @last_updated = Time.now
  end


  def aged_out?
    aged_out = Time.now - @last_updated > @age_max
    info "[Link::aged_out?] Age out: An Link entry, [#{@dpid1.to_hex}/#{@port1} - #{@dpid2.to_hex}/#{@port2}] has been aged-out" if aged_out
    aged_out
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


  def update
    # puts "Link::update] link: #{self.to_s} updated."
    @last_updated = Time.now
  end


end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
