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

When /^I turn down port (.+) on switch (.+)$/ do | port, switch |
  run "trema port_down --switch #{ switch } --port #{ port }"
  sleep 3
end

When /^I turn up port (.+) on switch (.+)$/ do | port, switch |
  run "trema port_up --switch #{ switch } --port #{ port }"
  sleep 6
end

When /^I kill switch (.+)$/ do | switch |
  run "trema kill #{ switch }"
  sleep 3
end

When /^I boot switch (.+)$/ do | switch |
  run "trema up #{ switch }"
  sleep 6
end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
