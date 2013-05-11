Feature: control multiple openflow switchies using routing_switch

  As a Trema user
  I want to control multiple openflow switches using routing_switch application
  So that I can send and receive packets


  @slow_process
#  @wip
  Scenario: One openflow switch and two hosts
    Given a file named "routing-switch.conf" with:
      """
      vswitch("switch1") { datapath_id "0xabc" }

      vhost("host1")
      vhost("host2")

      link "switch1", "host1"
      link "switch1", "host2"
      """
    When I run `trema run ../../my-routing-switch.rb -c routing-switch.conf -d`
    And wait until "MyRoutingSwitch" is up
    And *** sleep 10 ***
    Then switch1 should have a flow entry like nw_src=169.254.0.0/16,actions=drop
    And switch1 should have a flow entry like nw_src=224.0.0.0/24,actions=drop

    When I send 1 packet from host1 to host2
    Then the total number of tx packets should be:
      | host1 | host2 |
      |     1 |     0 |
    And the total number of rx packets should be:
      | host1 | host2 |
      |     0 |     0 |

    When I send 10 packets from host1 to host2
    Then the total number of tx packets should be:
      | host1 | host2 |
      |    11 |     0 |
    And the total number of rx packets should be:
      | host1 | host2 |
      |     0 |    10 |
    And switch1 should have a flow entry like dl_dst=00:00:00:00:00:02,nw_dst=192.168.0.2,actions=output

    When I send 10 packets from host2 to host1
    Then the total number of tx packets should be:
      | host1 | host2 |
      |    11 |    10 |
    And the total number of rx packets should be:
      | host1 | host2 |
      |    10 |    10 |
    And switch1 should have a flow entry like dl_dst=00:00:00:00:00:01,nw_dst=192.168.0.1,actions=output

#  @wip
  Scenario: Seven openflow switches and three hosts
    Given a file named "routing-switch.conf" with:
      """
      vswitch("sw1") { dpid "0x1" }
      vswitch("sw2") { dpid "0x2" }
      vswitch("sw3") { dpid "0x3" }
      vswitch("sw4") { dpid "0x4" }
      vswitch("sw5") { dpid "0x5" }
      vswitch("sw6") { dpid "0x6" }

      vhost ("host1") {
        ip "192.168.0.1"
        netmask "255.255.255.0"
        mac "00:00:00:01:00:01"
      }
      vhost ("host3") {
        ip "192.168.0.3"
        netmask "255.255.255.0"
        mac "00:00:00:01:00:03"
      }
      vhost ("host4") {
        ip "192.168.0.4"
        netmask "255.255.255.0"
        mac "00:00:00:01:00:04"
      }

      link "sw1", "sw2"
      link "sw2", "sw3"
      link "sw3", "sw4"
      link "sw4", "sw5"
      link "sw5", "sw6"
      link "sw6", "sw1"
      link "sw3", "sw6"
      link "sw2", "sw4"
      link "sw1", "host1"
      link "sw3", "host3"
      link "sw4", "host4"
      """
    When I run `trema run ../../my-routing-switch.rb -c routing-switch.conf -d`
    And wait until "MyRoutingSwitch" is up
    And *** sleep 10 ***

    When I send 1 packet from host1 to host3
    And I send 1 packet from host1 to host4
    Then the total number of tx packets should be:
      | host1 | host3 | host4 |
      |     2 |     0 |     0 |
    And the total number of rx packets should be:
      | host1 | host3 | host4 |
      |     0 |     0 |     0 |

    When I send 5 packets from host1 to host4
    Then the total number of tx packets should be:
      | host1 | host3 | host4 |
      |     7 |     0 |     0 |
    And the total number of rx packets should be:
      | host1 | host3 | host4 |
      |     0 |     0 |     5 |
    And sw1 should have a flow entry like dl_src=00:00:00:01:00:01,nw_src=192.168.0.1,dl_dst=00:00:00:01:00:04,nw_dst=192.168.0.4,actions=output
    And sw2 should have a flow entry like dl_src=00:00:00:01:00:01,nw_src=192.168.0.1,dl_dst=00:00:00:01:00:04,nw_dst=192.168.0.4,actions=output
    And sw4 should have a flow entry like dl_dst=00:00:00:01:00:04,nw_dst=192.168.0.4,actions=output

    When I send 5 packets from host4 to host1
    Then the total number of tx packets should be:
      | host1 | host3 | host4 |
      |     7 |     0 |     5 |
    And the total number of rx packets should be:
      | host1 | host3 | host4 |
      |     5 |     0 |     5 |
    And sw4 should have a flow entry like dl_src=00:00:00:01:00:04,nw_src=192.168.0.4,dl_dst=00:00:00:01:00:01,nw_dst=192.168.0.1,actions=output
    And sw2 should have a flow entry like dl_src=00:00:00:01:00:04,nw_src=192.168.0.4,dl_dst=00:00:00:01:00:01,nw_dst=192.168.0.1,actions=output
    And sw1 should have a flow entry like dl_dst=00:00:00:01:00:01,nw_dst=192.168.0.1,actions=output

    When I send 5 packets from host4 to host3
    Then the total number of tx packets should be:
      | host1 | host3 | host4 |
      |     7 |     0 |    10 |
    And the total number of rx packets should be:
      | host1 | host3 | host4 |
      |     5 |     5 |     5 |

    When I send 5 packets from host3 to host1
    Then the total number of tx packets should be:
      | host1 | host3 | host4 |
      |     7 |     5 |    10 |
    And the total number of rx packets should be:
      | host1 | host3 | host4 |
      |    10 |     5 |     5 |
