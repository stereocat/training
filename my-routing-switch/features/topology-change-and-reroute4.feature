Feature: topology change detection and re-routing test No.4

  As a Trema user
  I want to control multiple openflow switches using routing_switch application
  So that I can send and receive packets

  Background:
    Given a file named "routing-switch.conf" with:
      """
      vswitch("sw1") { dpid "0x1" }
      vswitch("sw2") { dpid "0x2" }
      vswitch("sw3") { dpid "0x3" }
      vswitch("sw4") { dpid "0x4" }
      vswitch("sw5") { dpid "0x5" }
      vswitch("sw6") { dpid "0x6" }
      vswitch("sw7") { dpid "0x7" }
      vswitch("sw8") { dpid "0x8" }
      vswitch("sw9") { dpid "0x9" }
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
      link "sw1", "sw2"
      link "sw2", "sw3"
      link "sw3", "sw4"
      link "sw4", "sw5"
      link "sw1", "sw6"
      link "sw6", "sw7"
      link "sw7", "sw8"
      link "sw8", "sw9"
      link "sw9", "sw5"
      link "host1", "sw1"
      link "host2", "sw5"
      """
    When I run `trema run ../../my-routing-switch.rb -c routing-switch.conf -d`
    And wait until "MyRoutingSwitch" is up
    And *** sleep 10 ***

  Scenario: Topology change by switch down/up and flow_mod to re-routing
    When I say "Step.1: with initial topology: topology_A"
    And I send 2 times 1 packet bidirectionally host1 and host2
    Then the total number of tx packets should be:
      | host1 | host2 |
      |     2 |     2 |
    And the total number of rx packets should be:
      | host1 | host2 |
      |     2 |     2 |
    # flow check: sw1
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:2"
    And sw1 should have a flow entry like "dl_dst=00:00:00:01:00:01,nw_dst=192.168.0.1 actions=output:3"
    # flow check: sw2
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:1"
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:2"
    # flow check: sw4
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:2"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"
    # flow check: sw5
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:3"
    And sw5 should have a flow entry like "dl_dst=00:00:00:01:00:02,nw_dst=192.168.0.2 actions=output:2"

    When I say "Step.2: kill one switch: sw3 and change to topology_B"
    And I kill switch sw3
    # flow check: sw1
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:2"
    And sw1 should have a flow entry like "dl_dst=00:00:00:01:00:01,nw_dst=192.168.0.1 actions=output:3"
    # flow check: sw2
    And sw2 should not have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:1"
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:2"
    # flow check: sw4
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:2"
    And sw4 should not have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"
    # flow check: sw5
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:3"
    And sw5 should have a flow entry like "dl_dst=00:00:00:01:00:02,nw_dst=192.168.0.2 actions=output:2"

    When I say "Step.3: send packets and flow check: topology_B"
    And I send 2 times 1 packet bidirectionally host1 and host2
    Then the total number of tx packets should be:
      | host1 | host2 |
      |     4 |     4 |
    And the total number of rx packets should be:
      | host1 | host2 |
      |     4 |     4 |
    # flow check: sw1
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:1"
    And sw1 should have a flow entry like "dl_dst=00:00:00:01:00:01,nw_dst=192.168.0.1 actions=output:3"
    # flow check: sw5
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"
    And sw5 should have a flow entry like "dl_dst=00:00:00:01:00:02,nw_dst=192.168.0.2 actions=output:2"

    When I say "Step.4 recover one switch: sw3 and change to topology_A"
    And I boot switch sw3
    # flow check: sw1
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:2"
    And sw1 should have a flow entry like "dl_dst=00:00:00:01:00:01,nw_dst=192.168.0.1 actions=output:3"
    # flow check: sw2
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:1"
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:2"
    # flow check: sw4
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:2"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"
    # flow check: sw5
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:3"
    And sw5 should have a flow entry like "dl_dst=00:00:00:01:00:02,nw_dst=192.168.0.2 actions=output:2"

    When I say "Step.5: send packets and flow check: topology_A"
    And I send 2 times 1 packet bidirectionally host1 and host2
    Then the total number of tx packets should be:
      | host1 | host2 |
      |     6 |     6 |
    And the total number of rx packets should be:
      | host1 | host2 |
      |     6 |     6 |
