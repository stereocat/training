require "forwardable"
require "link"
require "observer"
require "trema-extensions/port"
require "linkindex"

#
# Topology information containing the list of known switches, ports,
# and links.
#
class Topology
  include Observable
  extend Forwardable

  INFINITY_LINK_COST = 99999

  def_delegator :@ports, :each_pair, :each_switch
  def_delegator :@links, :each, :each_link


  def initialize view, controller
    @ports = Hash.new { [].freeze }
    @links = []
    @linkindex = LinkIndex.new
    @controller = controller
    add_observer view
    add_observer @linkindex
  end


  def delete_switch dpid
    @ports[ dpid ].each do | each |
      delete_port dpid, each
    end
    @ports.delete dpid
  end


  def update_port dpid, port
    if port.down?
      delete_port dpid, port
    elsif port.up?
      add_port dpid, port
    end
  end


  def add_port dpid, port
    @ports[ dpid ] += [ port ]

    # puts "# [add_port], dpid:#{dpid}"
    # puts "number:#{port.number}, name:#{port.name}"
  end


  def delete_port dpid, port
    @ports[ dpid ] -= [ port ]
    delete_link_by dpid, port
  end


  def add_link_by dpid, packet_in
    raise "Not an LLDP packet!" if not packet_in.lldp?

    link = Link.new( dpid, packet_in )

    if not @links.include?( link )

      # puts "# [add_link_by] not included link"
      # link.dump

      @links << link
      @links.sort!

      changed
      notify_observers self
    end
  end


  def switch_endpoint
    @linkindex.switch_endpoint
  end


  def link_between dpid1, dpid2
    @linkindex.link_between dpid1, dpid2
  end


  def get_path start, goal
    puts "[get_path], start:#{start}, goal:#{goal}"

    # start/goal are dpid
    dist = {}
    pred = {}
    remains = []

    # initialize
    @ports.each_key do | each |
      dist[each] = INFINITY_LINK_COST
      pred[each] = nil
      remains << each
    end
    dist[start] = 0

    while not remains.empty?

      # search node that has minimum distance in 'remines'
      pd = {}
      remains.each do | each |
        pd[each] = dist[each] # projection
      end
      (base_dpid, base_dist) = pd.to_a.sort { |a, b| a[1] <=> b[1] }.shift
      # fix minimum-distance node
      remains.delete(base_dpid)

      ## check
      puts "---------------:--------------------------"
      puts "remains        : [#{remains.join(", ")}]"
      puts "dist table     : {#{_pphash dist}}"
      puts "pred table     : {#{_pphash pred}}"
      puts "base (dist)    : #{base_dpid} (#{base_dist})"

      # search neighbors
      neighbors = @linkindex.neighbors_of(base_dpid)
      if neighbors
        neighbors.each do |each|
          # check if neighbor was not fixed
          if remains.include?(each)
            # update neighbors distance
            linkcost = @linkindex.link_between(base_dpid, each).cost
            newdist = dist[base_dpid] + linkcost
            if dist[each] > newdist
              dist[each] = newdist
              pred[each] = base_dpid
            end
          end
        end
      else
        warn "DPID:#{base_dpid} seems stand alone"
        break
      end

      ## check
      puts "neighbors      : [#{neighbors.join(", ")}]"
      puts "next dist tbl  : {#{_pphash dist}}"
    end

    return pred
  end


  ##############################################################################
  private
  ##############################################################################


  def delete_link_by dpid, port
    puts "[topology::delete_link_by] switch:#{dpid}, port:#{port.number}"

    link = @linkindex.link_of dpid, port.number
    if link
      puts "delete link: #{link.dpid1}/#{link.port1} - #{link.dpid2}/#{link.port2}"
      @controller.flow_remove_by_port link.dpid1, link.port1
      @controller.flow_remove_by_port link.dpid2, link.port2
      changed
      @links -= [ link ]
    end

    notify_observers self
  end


  # pretty-print of hash
  def _pphash hash
    str = ""
    hash.each_pair { |k,v| str = str + "#{k} => #{v}, " }
    return str
  end


end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
