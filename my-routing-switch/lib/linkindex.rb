require "link"
require "trema-extensions/port"


class LinkIndex

  attr_reader :switch_index
  attr_reader :switch_neighbor
  attr_reader :switch_endpoint


  def initialize
    @switch_index = {}
    @switch_neighbor = {}
    @switch_endpoint = {}
    @changed = false
  end


  def update topology
    puts "[LinkIndex::update]"

    @switch_index.clear
    @switch_neighbor.clear
    @switch_endpoint.clear

    topology.each_switch do | dpid, ports |
      @switch_index[dpid] = {}
      ports.each do |each|
        # puts "add port_obj to index: dpid:#{dpid.to_hex}, port:#{each.number}"
        @switch_index[dpid][each.number] = {}
        @switch_index[dpid][each.number][:port_obj] = each
        # puts "  num:#{@switch_index[dpid][each.number][:port_obj].number}"
      end
    end
    # always dpid/ports set is larger than dpid/links
    # if exists link_obj, then the port(link) is switch-to-switch
    topology.each_link do |each|
      # puts "add link_obj to index: dpid:#{each.dpid1.to_hex}, port:#{each.port1}"
      @switch_index[each.dpid1][each.port1][:link_obj] = each
      # puts "  num:#{@switch_index[each.dpid1][each.port1][:link_obj].port1}"
    end

    @switch_index.each_key do | dpid |
      @switch_neighbor[dpid] = []
      @switch_endpoint[dpid] = []

      @switch_index[dpid].each_key do | port_number |
        if @switch_index[dpid][port_number][:link_obj]
          link = @switch_index[dpid][port_number][:link_obj]
          @switch_neighbor[dpid].push(link.dpid2)
        else
          @switch_endpoint[dpid].push(port_number)
        end
      end
    end

    # dump
    @changed = true
  end


  def link_between dpid1, dpid2
    @switch_index[dpid1].each_key do | each |
      if @switch_index[dpid1][each][:link_obj]
        link = @switch_index[dpid1][each][:link_obj]
        return link if link.dpid2 == dpid2
      end
    end
    nil
  end


  def link_of dpid, port
    puts "[linkindex::link_of] #{dpid.to_hex}/#{port}"
    if @switch_index[dpid][port][:link_obj]
      return @switch_index[dpid][port][:link_obj]
    end
    nil
  end


  def dump
    puts "[LinkIndex::dump]"

    @switch_index.each_key do | dpid |
      puts "dpid: #{dpid.to_hex}"
      @switch_index[dpid].each_key do | each |
        port = @switch_index[dpid][each][:port_obj]
        link = @switch_index[dpid][each][:link_obj] ? @switch_index[dpid][each][:link_obj] : false
        puts "  port_number: #{each}"
        puts "    port_name    : #{port.name}"
        puts "    nbr dpid/port: #{link.dpid2.to_hex}/#{link.port2}" if link
      end

      puts "  neighbors: #{@switch_neighbor[dpid].join(', ')}"
      puts "  endports : #{@switch_endpoint[dpid].join(', ')}"
    end
  end


  def neighbors_of dpid
    @switch_neighbor[dpid]
  end


  def updated?
    @changed
  end


  def known
    @changed = false
  end


end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
