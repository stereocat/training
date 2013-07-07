Feature: control two openflow switch using routing_switch

  As a Trema user
  I want to control an openflow switch using routing_switch controller
  So that I can use it as a basic layer-2 switch

  Background:
    Given a file named "routing-switch.conf" with:
      """
      vswitch("sw1") { dpid "0x1" }
      vswitch("sw2") { dpid "0x2" }
      vhost ("host1") {
        ip "192.168.0.1"
        netmask "255.255.255.0"
        mac "00:00:00:01:00:01"
      }
      vhost ("host2") {
        ip "192.168.0.2"
        netmask "255.255.255.0"
        mac "00:00:00:01:00:02"
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
      link "host1", "sw1"
      link "host2", "sw1"
      link "host3", "sw2"
      link "host4", "sw2"
      """
    When I run `trema run ../../my-routing-switch.rb -c routing-switch.conf -d`
    And wait until "MyRoutingSwitch" is up
    And *** sleep 10 ***
    And I turn down port 2 on switch sw1


  Scenario: send one packet, between hosts connected on same swith (flooded)
    When I send 1 packet from host1 to host2
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host4 |
      |     1 |     0 |     0 |     0 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host4 |
      |     0 |     1 |     0 |     0 |
    When I send 1 packet from host3 to host4
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host4 |
      |     1 |     0 |     1 |     0 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host4 |
      |     0 |     1 |     0 |     1 |

  Scenario: send one packet, hosts on disconnected switches (NOT flooded)
    When I send 1 packet from host2 to host3
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host4 |
      |     0 |     1 |     0 |     0 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host4 |
      |     0 |     0 |     0 |     0 |
    When I send 1 packet from host4 to host1
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host4 |
      |     0 |     1 |     0 |     1 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host4 |
      |     0 |     0 |     0 |     0 |

  Scenario: linkup, send packets between each hosts and packets are flooded
    Given I turn up port 2 on switch sw1
    When I send 1 packet from host1 to host2
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host4 |
      |     1 |     0 |     0 |     0 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host4 |
      |     0 |     1 |     0 |     0 |
    When I send 1 packet from host2 to host3
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host4 |
      |     1 |     1 |     0 |     0 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host4 |
      |     0 |     1 |     1 |     0 |
    When I send 1 packet from host3 to host4
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host4 |
      |     1 |     1 |     1 |     0 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host4 |
      |     0 |     1 |     1 |     1 |
    When I send 1 packet from host4 to host1
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host4 |
      |     1 |     1 |     1 |     1 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host4 |
      |     1 |     1 |     1 |     1 |

  Scenario: linkup, send packets between each hosts and get new flow entries
    Given I turn up port 2 on switch sw1
    And I send 1 packet from host1 to host2
    And I send 1 packet from host2 to host3
    And I send 1 packet from host3 to host4
    And I send 1 packet from host4 to host1
    When I send 1 packet from host2 to host1
    And I send 1 packet from host3 to host2
    And I send 1 packet from host4 to host3
    And I send 1 packet from host1 to host4
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host4 |
      |     2 |     2 |     2 |     2 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host4 |
      |     2 |     2 |     2 |     2 |
      And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:04,nw_src=192.168.0.1,nw_dst=192.168.0.4 actions=output:2"
      And sw1 should have a flow entry like "dl_dst=00:00:00:01:00:01,nw_dst=192.168.0.1 actions=output:3"
      And sw2 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.3,nw_dst=192.168.0.2 actions=output:2"
      And sw2 should have a flow entry like "dl_dst=00:00:00:01:00:03,nw_dst=192.168.0.3 actions=output:3"


