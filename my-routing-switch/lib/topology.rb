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

  LINK_ENTRY_MAX_AGE = 5
  DEFAULT_LINK_COST = 10
  INFINITY_LINK_COST = 99999
  PRED_NONE = nil

  def_delegator :@ports, :each_pair, :each_switch
  def_delegator :@links, :each, :each_link
  def_delegators :@linkindex, :switch_endpoint, :link_between, :updated?, :known

  def initialize view, controller
    @ports = Hash.new { [].freeze }
    @links = []
    @linkindex = LinkIndex.new
    @controller = controller

    @dist = {}
    @pred = {}

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

    # puts "# [add_port], dpid:#{dpid.to_hex}"
    # puts "number:#{port.number}, name:#{port.name}"
  end


  def delete_port dpid, port
    @ports[ dpid ] -= [ port ]
    delete_link_by dpid, port
  end


  def add_link_by dpid, packet_in
    raise "Not an LLDP packet!" if not packet_in.lldp?

    link = Link.new( dpid, packet_in, DEFAULT_LINK_COST, LINK_ENTRY_MAX_AGE )

    if @links.include?( link )
      @links.each { | each | each.update if each == link }
    else
      puts "add link: #{link.dpid1.to_hex}/#{link.port1} - #{link.dpid2.to_hex}/#{link.port2}"
      @links << link
      @links.sort!
      changed
      notify_observers self
    end
  end


  def path_between start, goal
    puts "[get_path], start:#{start.to_hex}, goal:#{goal.to_hex}"

    return start == goal ? nil : @pred[start]
  end


  def has_path? start, goal
    start == goal ? true : @pred[start][goal]
  end


  # calculate shortest path of all switch pair
  # using "Floyd-Warshall" Algorithm
  def build_path
    return false if not @linkindex.updated?

    puts "Topology::build_path"
    @dist.clear
    @pred.clear

    # initialize dist/pred table
    each_switch do | dpid1, ports1 |
      @dist[dpid1] = {}
      @pred[dpid1] = {}
      each_switch do | dpid2, ports2 |
        link = @linkindex.link_between dpid1, dpid2
        if link
          @dist[dpid1][dpid2] = link.cost
          @pred[dpid1][dpid2] = dpid1
        else
          @dist[dpid1][dpid2] = INFINITY_LINK_COST
          @pred[dpid1][dpid2] = PRED_NONE
        end
      end
      @dist[dpid1][dpid1] = 0
    end

    # debug print
    _pptables "initial"

    # calc dist/pred table
    each_switch do | dpid_t, ports_t |
      each_switch do | dpid1, ports1 |
        each_switch do | dpid2, ports2 |
          linkcost = @dist[dpid1][dpid_t] + @dist[dpid_t][dpid2]
          if linkcost < @dist[dpid1][dpid2]
            @dist[dpid1][dpid2] = linkcost
            @pred[dpid1][dpid2] = @pred[dpid_t][dpid2]
          end
        end
      end

      # debug print
      _pptables "t=#{dpid_t.to_hex}"
    end

    @controller.rewrite_flows
    @linkindex.known
    return true
  end


  def age_links
    @links.each do |each|
      if each.aged_out?
        puts "[Topology::age_links], link: #{each.to_s} aged-out"
        @links -= [ each ]
        changed
      end
    end

    notify_observers self
  end


  ##############################################################################
  private
  ##############################################################################


  def delete_link_by dpid, port
    puts "[topology::delete_link_by] switch:#{dpid.to_hex}, port:#{port.number}"

    link = @linkindex.link_of dpid, port.number
    if link
      puts "delete link: #{link.dpid1.to_hex}/#{link.port1} - #{link.dpid2.to_hex}/#{link.port2}"
      @controller.flow_delete_by_port link.dpid1, link.port1
      @controller.flow_delete_by_port link.dpid2, link.port2
      changed
      @links -= [ link ]
    end

    notify_observers self
  end


  # pretty-print of dist/pred table
  def _pptables str
    puts "---------------------"
    puts str
    puts "dist :"
    _pphh @dist
    puts "pred :"
    _pphh @pred
  end

  # pretty-print of hash
  def _pph hash
    str = ""
    hash.sort.each { | k, v | str = str + sprintf("%x=>%6s, ", k, v) }
    return str
  end

  # pretty-print of double-hash
  def _pphh hash
    hash.sort.each do | dpid, h |
      puts "#{dpid.to_hex} : #{_pph h}"
    end
  end


end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
