#
# A router implementation in Trema
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

class Segments
  include Trema::Logger

  def initialize(segments)
    @db = {}
    segments.each { |each| @db[each[:name]] = each[:ports] }
  end


  def port_name_list_of(segment_name)
    @db[segment_name]
  end


  def include(port_name)
    info "[Segments::name_includes] search by #{ port_name }"

    @db.each do |name, port_list|
      puts "name_includes: port_list: #{ port_list.join(',') }"
      return name if port_list.include?(port_name)
    end
    nil
  end


  def dump
    puts "[Segments::dump]"

    @db.each do |name, port_list|
      puts "#{ name }, [#{ port_list.join(',') }]"
    end
  end
end
