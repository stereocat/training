require "graphviz"


module View
  class Graphviz
    def initialize output = "./topology.png"
      @output = File.expand_path( output )
    end


    def update topology
      g = GraphViz.new( :G, :use => "neato", :overlap => false, :splines => true )

      switch = {}
      topology.each_switch do | dpid, ports |
        port_labels = ports.map do |each|
          "<port#{each.number}>#{each.number.to_s}"
        end
        switch[ dpid ] = g.add_nodes(
          dpid.to_hex,
          "shape" => "record",
          "label" => "{DPID:#{dpid.to_hex} | {#{port_labels.join('|')}}}"
        )
      end

      topology.each_link do | each |
        if switch[ each.dpid1 ] and switch[ each.dpid2 ]
          g.add_edges(
            { switch[each.dpid1] => "port#{each.port1}" },
            { switch[each.dpid2] => "port#{each.port2}" },
            :dir => :none
          )
        end
      end

      g.output( :png => @output )
    end
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
