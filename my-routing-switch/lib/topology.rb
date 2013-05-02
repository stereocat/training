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


  def initialize controller
    @ports = Hash.new { [].freeze }
    @links = []
    @linkindex = LinkIndex.new
    add_observer controller
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


  def get_endpoint_ports
    @linkindex.switch_endpoint
  end


  def get_link dpid1, dpid2
    @linkindex.get_link dpid1, dpid2
  end


  def get_path start, goal
    puts "[get_path], start:#{start}, goal:#{goal}"

    # start/goal are dpid
    cost_table = {}
    before_node_table = {}
    remined_nodes = []
    fixed_nodes = []

    # initialize
    @ports.keys.each do | dpid |
      cost_table[dpid] = INFINITY_LINK_COST
      before_node_table[dpid] = nil
      remined_nodes.push(dpid)
    end

    # start node was fixed
    now = start
    cost_table[now] = 0

    while not remined_nodes.empty?
      ## check
      puts "---------------:--------------------------"
      puts "now            : #{now}"
      puts "cost_table     : {#{_pphash cost_table}}"
      puts "before_node tbl: {#{_pphash before_node_table}}"
      puts "remined_nodes  : [#{remined_nodes.join(", ")}]"
      puts "fixed_nodes    : [#{fixed_nodes.join(", ")}]"

      # search neighbors
      neighbors = @linkindex.neighbors_of(now)
      if neighbors

        # delete fixed nodes from neighbors
        neighbors -= fixed_nodes

        # update cost of remined nodes (not fixed nodes)
        neighbors.each do |each|
          linkcost = cost_table[now] + @linkindex.get_link(now, each).cost
          if cost_table[each] > linkcost
            cost_table[each] = linkcost
            before_node_table[each] = now
          end
        end

        # fix current node (minimum cost in remined_nodes)
        remined_nodes.delete(now)
        fixed_nodes.push(now)

        # search minimum cost in remined_nodes and set next 'now'
        min_cost = INFINITY_LINK_COST
        min_node = nil
        remined_nodes.each do |each|
          if min_cost >= cost_table[each]
            min_cost = cost_table[each]
            min_node = each
          end
        end

        ## check
        puts "neighbors      : [#{neighbors.join(", ")}]"
        puts "next cost tbl  : {#{_pphash cost_table}}"
        puts "fixed node     : #{now} (cost: #{cost_table[now]})"
        puts "next node      : #{min_node} (cost: #{min_cost})"

        now = min_node
      else
        warn "DPID:#{now}: Stand Alone Switch?"
        break
      end
    end

    return before_node_table
  end


  ##############################################################################
  private
  ##############################################################################


  def delete_link_by dpid, port
    @links.each do | each |
      if each.has?( dpid, port.number )
        changed
        @links -= [ each ]
      end
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
