class FlowEntry
  attr_reader :macsa
  attr_reader :macda
  attr_reader :eth_type
  attr_reader :ipv4_saddr
  attr_reader :ipv4_daddr
  attr_reader :path


  def initialize macsa, macda, eth_type, ipv4_saddr, ipv4_daddr, path
    @macsa = macsa
    @macda = macda
    @eth_type = eth_type
    @ipv4_saddr = ipv4_saddr
    @ipv4_daddr = ipv4_daddr
    @path = path
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
    "[#{ @macsa.to_s}, #{ @ipv4_saddr.to_s }]->[#{ @macda.to_s }, #{ @ipv4_daddr.to_s}] #{ @path.join(',') }"
  end


  def update_path path
    @path = path
  end


end


class FlowIndex
  attr_reader :flows

  def initialize
    @flows = []
  end


  def add_by_packet_in dpid, packet_in, path
    add(
      dpid,
      packet_in.macsa,
      packet_in.macda,
      packet_in.eth_type,
      packet_in.ipv4_saddr,
      packet_in.ipv4_daddr,
      path
    )
  end


  def delete_by_flow_removed dpid, flow_removed
    match = flow_removed.match
    delete(
      dpid,
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
  def add dpid, macsa, macda, eth_type, ipv4_saddr, ipv4_daddr, path
    puts "[FlowIndex::add] #{dpid},#{macsa},#{macda},#{eth_type.to_hex},#{ipv4_saddr},#{ipv4_daddr}"

    flow = FlowEntry.new(
      macsa,
      macda,
      eth_type,
      ipv4_saddr,
      ipv4_daddr,
      path
    )
    @flows << flow
  end


  # args are Trema::Mac/Trema::IP object
  def delete dpid, macsa, macda, eth_type, ipv4_saddr, ipv4_daddr
    puts "[FlowIndex::delete] #{dpid},#{macsa},#{macda},#{eth_type.to_hex},#{ipv4_saddr},#{ipv4_daddr}"

    flow = FlowEntry.new(
      macsa,
      macda,
      eth_type,
      ipv4_saddr,
      ipv4_daddr,
      nil # dummy
    )
    @flows.delete_if do | each |
      # "path", there is no need to contain last-hop of path.
      # because last-hop is always used by old and new path.
      (each.path.include?(dpid)) and (each == flow)
    end
  end


end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
