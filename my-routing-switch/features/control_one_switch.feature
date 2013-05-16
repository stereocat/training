Feature: control one openflow switch using routing_switch

  As a Trema user
  I want to control an openflow switch using routing_switch controller
  So that I can use it as a basic layer-2 switch

  Background:
    Given a file named "routing-switch.conf" with:
      """
      vswitch("switch1") { datapath_id "0xabc" }

      vhost("host1") {
        ip "192.168.0.1"
        mac "00:00:00:00:00:01"
      }
      vhost("host2") {
        ip "192.168.0.2"
        mac "00:00:00:00:00:02"
      }

      link "switch1", "host1"
      link "switch1", "host2"
      """
    When I run `trema run ../../my-routing-switch.rb -c routing-switch.conf -d`
    And wait until "MyRoutingSwitch" is up
    And *** sleep 10 ***

  Scenario: default flow entries that drops packets from link-local and multicast address
    Then switch1 should have a flow entry like "nw_src=169.254.0.0/16,actions=drop"
    And switch1 should have a flow entry like "nw_src=224.0.0.0/24,actions=drop"

  Scenario: send one packet, and the packet is dropped
    When I send 1 packet from host1 to host2
    Then the total number of tx packets should be:
      | host1 | host2 |
      |     1 |     0 |
    And the total number of rx packets should be:
      | host1 | host2 |
      |     0 |     0 |

  Scenario: send packets, and get a new flow entry
    Given I send 1 packet from host1 to host2
    When I send 10 packets from host1 to host2
    Then the total number of tx packets should be:
      | host1 | host2 |
      |    11 |     0 |
    And the total number of rx packets should be:
      | host1 | host2 |
      |     0 |    10 |
    And switch1 should have a flow entry like "dl_dst=00:00:00:00:00:02,nw_dst=192.168.0.2,actions=output"

  Scenario: send packets bidirectionally, and get a flow entry
    Given I send 1 packet from host1 to host2
    When I send 10 packets from host1 to host2
    And I send 10 packets from host2 to host1
    Then the total number of tx packets should be:
      | host1 | host2 |
      |    11 |    10 |
    And the total number of rx packets should be:
      | host1 | host2 |
      |    10 |    10 |
    And switch1 should have a flow entry like "dl_dst=00:00:00:00:00:01,nw_dst=192.168.0.1,actions=output"
    And switch1 should have a flow entry like "dl_dst=00:00:00:00:00:02,nw_dst=192.168.0.2,actions=output"
