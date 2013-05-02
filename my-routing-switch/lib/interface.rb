
# interface class to use router-utils

class Interface
  attr_reader :hwaddr
  attr_reader :ipaddr

  def initialize(hwaddr, ipaddr)
    @hwaddr = hwaddr # Mac Object
    @ipaddr = ipaddr # IPAddr Object
  end
end
