Feature: topology change detection and re-routing test No.5

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
      link "sw2", "sw3"
      link "sw2", "sw3"
      link "sw3", "sw4"
      link "sw1", "sw5"
      link "sw5", "sw6"
      link "sw6", "sw7"
      link "sw7", "sw4"
      link "host1", "sw1"
      link "host2", "sw4"
      link "host3", "sw7"
      link "host4", "sw5"
      """
    When I run `trema run ../../my-routing-switch.rb -c routing-switch.conf -d`
    And wait until "MyRoutingSwitch" is up
    And *** sleep 10 ***

  Scenario: Topology change by switch down/up, with separated env.
    When I say "Step.1: with initial topology: topology_A2"
    And I send 2 times 1 packet bidirectionally host1 and host2
    And I send 2 times 1 packet bidirectionally host2 and host3
    And I send 2 times 1 packet bidirectionally host3 and host4
    And I send 2 times 1 packet bidirectionally host4 and host1
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host4 |
      |     4 |     4 |     4 |     4 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host4 |
      |     4 |     4 |     4 |     4 |
    # flow check: sw1
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:3"
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:04,nw_src=192.168.0.1,nw_dst=192.168.0.4 actions=output:1"
    And sw1 should have a flow entry like "dl_dst=00:00:00:01:00:01,nw_dst=192.168.0.1 actions=output:2"
    # flow check: sw2
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:1"
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:3"
    # flow check: sw3
    And sw3 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:3"
    And sw3 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"
    # flow check: sw4
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.2,nw_dst=192.168.0.3 actions=output:1"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:3"
    And sw4 should have a flow entry like "dl_dst=00:00:00:01:00:02,nw_dst=192.168.0.2 actions=output:2"
    # flow check: sw5
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:04,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.4,nw_dst=192.168.0.1 actions=output:2"
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:04,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.4,nw_dst=192.168.0.3 actions=output:3"
    And sw5 should have a flow entry like "dl_dst=00:00:00:01:00:04,nw_dst=192.168.0.4 actions=output:1"
    # flow check: sw6
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:04,nw_src=192.168.0.3,nw_dst=192.168.0.4 actions=output:2"
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:04,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.4,nw_dst=192.168.0.3 actions=output:1"
    # flow check: sw7
    And sw7 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:04,nw_src=192.168.0.3,nw_dst=192.168.0.4 actions=output:1"
    And sw7 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.3,nw_dst=192.168.0.2 actions=output:2"
    And sw7 should have a flow entry like "dl_dst=00:00:00:01:00:03,nw_dst=192.168.0.3 actions=output:3"

    When I say "Step.2: down one link between sw2-sw3: topology_A1"
    And I turn down port 1 on switch sw2
    # flow check: sw2
    And sw2 should not have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:1"

    When I say "Step.3: send packets and flow check: topology_A1"
    And I send 2 times 1 packet bidirectionally host1 and host2
    And I send 2 times 1 packet bidirectionally host2 and host3
    And I send 2 times 1 packet bidirectionally host3 and host4
    And I send 2 times 1 packet bidirectionally host4 and host1
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host4 |
      |     8 |     8 |     8 |     8 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host4 |
      |     8 |     8 |     8 |     8 |
    # flow check: sw2
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:2"

    When I say "Step.4: down one link between sw2-sw3: topology_B"
    And I turn down port 1 on switch sw3
    # flow check: sw2
    And sw2 should not have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:2"
    # flow check: sw3
    And sw3 should not have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"

    When I say "Step.5: send packets and flow check: topology_B"
    And I send 2 times 1 packet bidirectionally host1 and host2
    And I send 2 times 1 packet bidirectionally host2 and host3
    And I send 2 times 1 packet bidirectionally host3 and host4
    And I send 2 times 1 packet bidirectionally host4 and host1
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host4 |
      |    12 |    12 |    12 |    12 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host4 |
      |    12 |    12 |    12 |    12 |
    # flow check: sw1
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:1"
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:04,nw_src=192.168.0.1,nw_dst=192.168.0.4 actions=output:1"
    And sw1 should have a flow entry like "dl_dst=00:00:00:01:00:01,nw_dst=192.168.0.1 actions=output:2"
    # flow check: sw4
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.2,nw_dst=192.168.0.3 actions=output:1"
    And sw4 should have a flow entry like "dl_dst=00:00:00:01:00:02,nw_dst=192.168.0.2 actions=output:2"
    # flow check: sw5
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:3"
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:2"
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:04,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.4,nw_dst=192.168.0.1 actions=output:2"
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:04,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.4,nw_dst=192.168.0.3 actions=output:3"
    And sw5 should have a flow entry like "dl_dst=00:00:00:01:00:04,nw_dst=192.168.0.4 actions=output:1"
    # flow check: sw6
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:1"
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:2"
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:04,nw_src=192.168.0.3,nw_dst=192.168.0.4 actions=output:2"
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:04,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.4,nw_dst=192.168.0.3 actions=output:1"
    # flow check: sw7
    And sw7 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:2"
    And sw7 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"
    And sw7 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.3,nw_dst=192.168.0.2 actions=output:2"
    And sw7 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:04,nw_src=192.168.0.3,nw_dst=192.168.0.4 actions=output:1"
    And sw7 should have a flow entry like "dl_dst=00:00:00:01:00:03,nw_dst=192.168.0.3 actions=output:3"

    When I say "Step.6: kill one switch: sw6 and change to topology_C"
    And I kill switch sw6
    # flow check: sw5
    And sw5 should not have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:3"
    And sw5 should not have a flow entry like "dl_src=00:00:00:01:00:04,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.4,nw_dst=192.168.0.3 actions=output:3"
    # flow check: sw7
    And sw7 should not have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"
    And sw7 should not have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:04,nw_src=192.168.0.3,nw_dst=192.168.0.4 actions=output:1"

    When I say "Step.7: send packets and flow check: topology_C"
    And I send 2 times 1 packet bidirectionally host1 and host2
    And I send 2 times 1 packet bidirectionally host2 and host3
    And I send 2 times 1 packet bidirectionally host3 and host4
    And I send 2 times 1 packet bidirectionally host4 and host1
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host4 |
      |    16 |    16 |    16 |    16 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host4 |
      |    14 |    14 |    14 |    14 |
    # flow check: sw5
    And sw5 should not have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:3"
    And sw5 should not have a flow entry like "dl_src=00:00:00:01:00:04,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.4,nw_dst=192.168.0.3 actions=output:3"
    # flow check: sw7
    And sw7 should not have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"
    And sw7 should not have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:04,nw_src=192.168.0.3,nw_dst=192.168.0.4 actions=output:1"

    When I say "Step.8 recover one switch: sw6 and change to topology_B"
    And I boot switch sw6
    # flow check: sw1
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:1"
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:04,nw_src=192.168.0.1,nw_dst=192.168.0.4 actions=output:1"
    And sw1 should have a flow entry like "dl_dst=00:00:00:01:00:01,nw_dst=192.168.0.1 actions=output:2"
    # flow check: sw4
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.2,nw_dst=192.168.0.3 actions=output:1"
    And sw4 should have a flow entry like "dl_dst=00:00:00:01:00:02,nw_dst=192.168.0.2 actions=output:2"
    # flow check: sw5
    And sw5 should not have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:3"
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:2"
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:04,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.4,nw_dst=192.168.0.1 actions=output:2"
    And sw5 should not have a flow entry like "dl_src=00:00:00:01:00:04,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.4,nw_dst=192.168.0.3 actions=output:3"
    And sw5 should have a flow entry like "dl_dst=00:00:00:01:00:04,nw_dst=192.168.0.4 actions=output:1"
    # flow check: sw6 (initial, sw6 has default flow entry [drop actions])
    And the number of flow entries on sw6 should be 2
    # flow check: sw7
    And sw7 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:2"
    And sw7 should not have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"
    And sw7 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.3,nw_dst=192.168.0.2 actions=output:2"
    And sw7 should not have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:04,nw_src=192.168.0.3,nw_dst=192.168.0.4 actions=output:1"
    And sw7 should have a flow entry like "dl_dst=00:00:00:01:00:03,nw_dst=192.168.0.3 actions=output:3"

    When I say "Step.9: send packets and flow check: topology_B"
    And I send 2 times 1 packet bidirectionally host1 and host2
    And I send 2 times 1 packet bidirectionally host2 and host3
    And I send 2 times 1 packet bidirectionally host3 and host4
    And I send 2 times 1 packet bidirectionally host4 and host1
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host4 |
      |    20 |    20 |    20 |    20 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host4 |
      |    18 |    18 |    18 |    18 |
    # flow check: sw5
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:3"
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:04,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.4,nw_dst=192.168.0.3 actions=output:3"
    And sw5 should have a flow entry like "dl_dst=00:00:00:01:00:04,nw_dst=192.168.0.4 actions=output:1"
    # flow check: sw6
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:1"
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:2"
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:04,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.4,nw_dst=192.168.0.3 actions=output:1"
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:04,nw_src=192.168.0.3,nw_dst=192.168.0.4 actions=output:2"
    # flow check: sw7
    And sw7 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"
    And sw7 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:04,nw_src=192.168.0.3,nw_dst=192.168.0.4 actions=output:1"

    When I say "Step.10: recover link between sw2-sw3, change topology_B to topology_A1"
    And I turn up port 1 on switch sw3
    # flow check: sw1
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:3"
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:04,nw_src=192.168.0.1,nw_dst=192.168.0.4 actions=output:1"
    And sw1 should have a flow entry like "dl_dst=00:00:00:01:00:01,nw_dst=192.168.0.1 actions=output:2"
    # flow check: sw2
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:2"
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:3"
    # flow check: sw3
    And sw3 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:3"
    And sw3 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"
    # flow check: sw4
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.2,nw_dst=192.168.0.3 actions=output:1"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:3"
    And sw4 should have a flow entry like "dl_dst=00:00:00:01:00:02,nw_dst=192.168.0.2 actions=output:2"
    # flow check: sw5
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:04,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.4,nw_dst=192.168.0.1 actions=output:2"
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:04,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.4,nw_dst=192.168.0.3 actions=output:3"
    And sw5 should have a flow entry like "dl_dst=00:00:00:01:00:04,nw_dst=192.168.0.4 actions=output:1"
    # flow check: sw6
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:04,nw_src=192.168.0.3,nw_dst=192.168.0.4 actions=output:2"
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:04,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.4,nw_dst=192.168.0.3 actions=output:1"
    # flow check: sw7
    And sw7 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:04,nw_src=192.168.0.3,nw_dst=192.168.0.4 actions=output:1"
    And sw7 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.3,nw_dst=192.168.0.2 actions=output:2"
    And sw7 should have a flow entry like "dl_dst=00:00:00:01:00:03,nw_dst=192.168.0.3 actions=output:3"

    When I say "Step.11: send packets and flow check: topology_A1"
    And I send 2 times 1 packet bidirectionally host1 and host2
    And I send 2 times 1 packet bidirectionally host2 and host3
    And I send 2 times 1 packet bidirectionally host3 and host4
    And I send 2 times 1 packet bidirectionally host4 and host1
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host4 |
      |    24 |    24 |    24 |    24 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host4 |
      |    22 |    22 |    22 |    22 |

    When I say "Step.12: recover link between sw2-sw3, change topology_A1 to topology_A2"
    And I turn up port 1 on switch sw2
    # flow check: sw2
    And sw2 should not have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:2"
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:1"

    When I say "Step.13: send packets and flow check: topology_A2"
    And I send 2 times 1 packet bidirectionally host1 and host2
    And I send 2 times 1 packet bidirectionally host2 and host3
    And I send 2 times 1 packet bidirectionally host3 and host4
    And I send 2 times 1 packet bidirectionally host4 and host1
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host4 |
      |    28 |    28 |    28 |    28 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host4 |
      |    26 |    26 |    26 |    26 |
