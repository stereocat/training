class FlowEntry
  attr_reader :macsa
  attr_reader :macda
  attr_reader :eth_type
  attr_reader :ipv4_saddr
  attr_reader :ipv4_daddr


  def initialize macsa, macda, eth_type, ipv4_saddr, ipv4_daddr
    @macsa = macsa
    @macda = macda
    @eth_type = eth_type
    @ipv4_saddr = ipv4_saddr
    @ipv4_daddr = ipv4_daddr
  end


  def == other
    ( @macsa.to_s == other.macsa.to_s ) and
      ( @macda.to_s == other.macda.to_s ) and
      ( @ipv4_saddr.to_s == other.ipv4_saddr.to_s ) and
      ( @ipv4_daddr.to_s == other.ipv4_daddr.to_s )
  end


  def <=> other
    to_s <=> other.to_s
  end


  def to_s
    "[#{ @macsa.to_s}, #{ @ipv4_saddr.to_s }]->[#{ @macda.to_s }, #{ @ipv4_daddr.to_s}]"
  end


end


class FlowIndex
  attr_reader :flows

  def initialize
    @flows = []
  end


  def add_by_packet_in packet_in
    add(
      packet_in.macsa,
      packet_in.macda,
      packet_in.eth_type,
      packet_in.ipv4_saddr,
      packet_in.ipv4_daddr
    )
  end

  def delete_by_flow_removed flow_removed
    match = flow_removed.match
    delete(
      match.dl_src,
      match.dl_dst,
      match.dl_type,
      match.nw_src,
      match.nw_dst
    )
  end


  def dump
    puts "[FlowIndex::dump]"
    @flows.each { | each | puts each.to_s }
  end


  ##############################################################################
  private
  ##############################################################################


  # args are Trema::Mac/Trema::IP object
  def add macsa, macda, eth_type, ipv4_saddr, ipv4_daddr
    puts "[FlowIndex::add] #{macsa},#{macda},#{eth_type.to_hex},#{ipv4_saddr},#{ipv4_daddr}"

    flow = FlowEntry.new macsa, macda, eth_type, ipv4_saddr, ipv4_daddr
    @flows << flow
  end


  # args are Trema::Mac/Trema::IP object
  def delete macsa, macda, eth_type, ipv4_saddr, ipv4_daddr
    puts "[FlowIndex::delete] #{macsa},#{macda},#{eth_type.to_hex},#{ipv4_saddr},#{ipv4_daddr}"

    flow = FlowEntry.new macsa, macda, eth_type, ipv4_saddr, ipv4_daddr
    @flows.delete_if { | each | each == flow }
  end


end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
