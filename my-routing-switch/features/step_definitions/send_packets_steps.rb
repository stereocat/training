#
# Copyright (C) 2008-2012 NEC Corporation
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#


When /^I send (\d+) packets from (.+) to (.+)$/ do | n_packets, host_a, host_b |
  run "trema send_packets --source #{ host_a } --dest #{ host_b } --n_pkts #{ n_packets }"
  sleep [10, n_packets.to_i].min  # ensure that all packets are sent
end


When /^I send 1 packet from (.+) to (.+)$/ do | host_a, host_b |
  step "I send 1 packets from #{ host_a } to #{ host_b }"
end


When /^I send packets from (.+) to (.+) \(duration = (\d+)\)$/ do | host_a, host_b, duration |
  run "trema send_packets --source #{ host_a } --dest #{ host_b } --duration #{ duration }"
end


When /^I send 1 packet bidirectionally (.+) and (.+)$/ do | host_a, host_b |
  step "I send 1 packet from #{ host_a } to #{ host_b }"
  step "I send 1 packet from #{ host_b } to #{ host_a }"
end

When /^I send (\d+) times 1 packet bidirectionally (.+) and (.+)$/ do | times, host_a, host_b |
  times.to_i.times do |i|
    step "I send 1 packet from #{ host_a } to #{ host_b }"
    step "I send 1 packet from #{ host_b } to #{ host_a }"
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
