Feature: topology change detection and re-routing test No.3

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
      vhost ("host5") {
        ip "192.168.0.5"
        netmask "255.255.255.0"
        mac "00:00:00:01:00:05"
      }
      vhost ("host6") {
        ip "192.168.0.6"
        netmask "255.255.255.0"
        mac "00:00:00:01:00:06"
      }
      link "sw1", "sw2"
      link "sw1", "sw4"
      link "sw2", "sw3"
      link "sw3", "sw5"
      link "sw4", "sw5"
      link "sw4", "sw6"
      link "sw5", "sw6"
      link "sw1", "host1"
      link "sw2", "host2"
      link "sw3", "host3"
      link "sw5", "host5"
      link "sw6", "host6"
      """
    When I run `trema run ../../my-routing-switch.rb -c routing-switch.conf -d`
    And wait until "MyRoutingSwitch" is up
    And *** sleep 10 ***

  Scenario: Topology change by link down/up and flow_mod to re-routing
    When I say "Step.1: with initial topology: topology_A"
    And I send 2 times 1 packet bidirectionally host1 and host2
    And I send 2 times 1 packet bidirectionally host1 and host3
    And I send 2 times 1 packet bidirectionally host1 and host5
    And I send 2 times 1 packet bidirectionally host1 and host6
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host5 | host6 |
      |     8 |     2 |     2 |     2 |     2 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host5 | host6 |
      |     8 |     2 |     2 |     2 |     2 |
    # flow check: sw1: forward (host1 -> host2,3,5,6)
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:3"
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:3"
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:05,nw_src=192.168.0.1,nw_dst=192.168.0.5 actions=output:1"
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:06,nw_src=192.168.0.1,nw_dst=192.168.0.6 actions=output:1"
    # flow check: sw1: reverse (host2,3,5,6 -> host1)
    And sw1 should have a flow entry like "dl_dst=00:00:00:01:00:01,nw_dst=192.168.0.1 actions=output:2"
    # flow check: sw2: forward (host1 -> host2,3)
    And sw2 should have a flow entry like "dl_dst=00:00:00:01:00:02,nw_dst=192.168.0.2 actions=output:2"
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:1"
    # flow check: sw2: reverse (host2,3 -> host1)
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:3"
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:3"
    # flow check: sw3: forward (host1 -> host3)
    And sw3 should have a flow entry like "dl_dst=00:00:00:01:00:03,nw_dst=192.168.0.3 actions=output:1"
    # flow check: sw3: reverse (host3 -> host1)
    And sw3 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:2"
    # flow check: sw4: forward (host1 -> host5,6)
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:05,nw_src=192.168.0.1,nw_dst=192.168.0.5 actions=output:1"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:06,nw_src=192.168.0.1,nw_dst=192.168.0.6 actions=output:3"
    # flow check: sw4: reverse (host5,6 -> host1)
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:05,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.5,nw_dst=192.168.0.1 actions=output:2"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:06,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.6,nw_dst=192.168.0.1 actions=output:2"

    When I say "Step.2: down one link between sw2-sw3: topology_B"
    And I turn down port 1 on switch sw2
    # flow check: sw2: forward (host1 -> host2,3)
    And sw2 should have a flow entry like "dl_dst=00:00:00:01:00:02,nw_dst=192.168.0.2 actions=output:2"
    And sw2 should not have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:1"
    # flow check: sw2: reverse (host2,3 -> host1)
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:3"
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:3"
    # flow check: sw3: forward (host1 -> host3)
    And sw3 should have a flow entry like "dl_dst=00:00:00:01:00:03,nw_dst=192.168.0.3 actions=output:1"
    # flow check: sw3: reverse (host3 -> host1)
    And sw3 should not have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:2"

    When I say "Step.3: send packets and flow check: topology_B"
    And I send 2 times 1 packet bidirectionally host1 and host2
    And I send 2 times 1 packet bidirectionally host1 and host3
    And I send 2 times 1 packet bidirectionally host1 and host5
    And I send 2 times 1 packet bidirectionally host1 and host6
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host5 | host6 |
      |    16 |     4 |     4 |     4 |     4 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host5 | host6 |
      |    16 |     4 |     4 |     4 |     4 |
    # flow check: sw1: forward (host1 -> host 2,3,5,6)
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:3"
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:1"
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:05,nw_src=192.168.0.1,nw_dst=192.168.0.5 actions=output:1"
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:06,nw_src=192.168.0.1,nw_dst=192.168.0.6 actions=output:1"
    # flow check: sw1: reverse (host2,3,5,6 -> host1)
    And sw1 should have a flow entry like "dl_dst=00:00:00:01:00:01,nw_dst=192.168.0.1 actions=output:2"
    # flow check: sw2: forward (host1 -> host2)
    And sw2 should have a flow entry like "dl_dst=00:00:00:01:00:02,nw_dst=192.168.0.2 actions=output:2"
    # flow check: sw2: reverse (host2 -> host1)
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:3"
    # flow check: sw3: forward (host1 -> host3)
    And sw3 should have a flow entry like "dl_dst=00:00:00:01:00:03,nw_dst=192.168.0.3 actions=output:1"
    # flow check: sw3: reverse (host3 -> host1)
    And sw3 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:3"
    # flow check: sw4: forward (host1 -> host3,5,6)
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:1"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:05,nw_src=192.168.0.1,nw_dst=192.168.0.5 actions=output:1"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:06,nw_src=192.168.0.1,nw_dst=192.168.0.6 actions=output:3"
    # flow check: sw4: reverse (host3,5,6 -> host1)
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:2"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:05,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.5,nw_dst=192.168.0.1 actions=output:2"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:06,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.6,nw_dst=192.168.0.1 actions=output:2"
    # flow check: sw5: forward (host1 -> host3,5)
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:4"
    And sw5 should have a flow entry like "dl_dst=00:00:00:01:00:05,nw_dst=192.168.0.5 actions=output:1"
    # flow check: sw5: forward (host3,5 -> host1)
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:3"
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:05,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.5,nw_dst=192.168.0.1 actions=output:3"
    # flow check: sw6: forward (host1 -> host6)
    And sw6 should have a flow entry like "dl_dst=00:00:00:01:00:06,nw_dst=192.168.0.6 actions=output:1"
    # flow check: sw6: reverse (host6 -> host1)
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:06,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.6,nw_dst=192.168.0.1 actions=output:3"

    When I say "Step.4: down one link between sw4-sw5: topology_C"
    And I turn down port 3 on switch sw5
    # flow check: sw4: forward (host1 -> host3,5,6)
    And sw4 should not have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:1"
    And sw4 should not have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:05,nw_src=192.168.0.1,nw_dst=192.168.0.5 actions=output:1"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:06,nw_src=192.168.0.1,nw_dst=192.168.0.6 actions=output:3"
    # flow check: sw4: reverse (host3,5,6 -> host1)
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:2"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:05,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.5,nw_dst=192.168.0.1 actions=output:2"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:06,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.6,nw_dst=192.168.0.1 actions=output:2"
    # flow check: sw5: forward (host1 -> host3,5)
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:4"
    And sw5 should have a flow entry like "dl_dst=00:00:00:01:00:05,nw_dst=192.168.0.5 actions=output:1"
    # flow check: sw5: forward (host3,5 -> host1)
    And sw5 should not have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:3"
    And sw5 should not have a flow entry like "dl_src=00:00:00:01:00:05,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.5,nw_dst=192.168.0.1 actions=output:3"
    # flow check: sw6: forward (host1 -> host6)
    And sw6 should have a flow entry like "dl_dst=00:00:00:01:00:06,nw_dst=192.168.0.6 actions=output:1"
    # flow check: sw6: reverse (host6 -> host1)
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:06,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.6,nw_dst=192.168.0.1 actions=output:3"

    When I say "Step.5: send packets and flow check: topology_C"
    And I send 2 times 1 packet bidirectionally host1 and host2
    And I send 2 times 1 packet bidirectionally host1 and host3
    And I send 2 times 1 packet bidirectionally host1 and host5
    And I send 2 times 1 packet bidirectionally host1 and host6
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host5 | host6 |
      |    24 |     6 |     6 |     6 |     6 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host5 | host6 |
      |    24 |     6 |     6 |     6 |     6 |
    # flow check: sw1: forward (host1 -> host2,3,5,6)
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:3"
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:1"
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:05,nw_src=192.168.0.1,nw_dst=192.168.0.5 actions=output:1"
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:06,nw_src=192.168.0.1,nw_dst=192.168.0.6 actions=output:1"
    # flow check: sw1: reverse (host2,3,5,6 -> host1)
    And sw1 should have a flow entry like "dl_dst=00:00:00:01:00:01,nw_dst=192.168.0.1 actions=output:2"
    # flow check: sw2: forward (host1 -> host2)
    And sw2 should have a flow entry like "dl_dst=00:00:00:01:00:02,nw_dst=192.168.0.2 actions=output:2"
    # flow check: sw2: reverse (host2 -> host1)
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:3"
    # flow check: sw3: forward (host1 -> host3)
    And sw3 should have a flow entry like "dl_dst=00:00:00:01:00:03,nw_dst=192.168.0.3 actions=output:1"
    # flow check: sw3: reverse (host3 -> host1)
    And sw3 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:3"
    # flow check: sw4: forward (host1 -> host3,5,6)
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:3"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:05,nw_src=192.168.0.1,nw_dst=192.168.0.5 actions=output:3"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:06,nw_src=192.168.0.1,nw_dst=192.168.0.6 actions=output:3"
    # flow check: sw4: reverse (host3,5,6 -> host1)
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:2"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:05,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.5,nw_dst=192.168.0.1 actions=output:2"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:06,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.6,nw_dst=192.168.0.1 actions=output:2"
    # flow check: sw5: forward (host1 -> host3,5)
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:4"
    And sw5 should have a flow entry like "dl_dst=00:00:00:01:00:05,nw_dst=192.168.0.5 actions=output:1"
    # flow check: sw5: reverse (host3,5 -> host1)
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:2"
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:05,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.5,nw_dst=192.168.0.1 actions=output:2"
    # flow check: sw6: forward (host1 -> host3,5,6)
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:2"
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:05,nw_src=192.168.0.1,nw_dst=192.168.0.5 actions=output:2"
    And sw6 should have a flow entry like "dl_dst=00:00:00:01:00:06,nw_dst=192.168.0.6 actions=output:1"
    # flow check: sw6: reverse (host3,5,6 -> host1)
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:3"
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:05,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.5,nw_dst=192.168.0.1 actions=output:3"
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:06,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.6,nw_dst=192.168.0.1 actions=output:3"

    When I say "Step.6: recover link between sw4-sw5, change topology_C to topology_B"
    And I turn up port 3 on switch sw5
    # flow check: sw1: forward (host1 -> host 2,3,5,6)
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:3"
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:1"
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:05,nw_src=192.168.0.1,nw_dst=192.168.0.5 actions=output:1"
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:06,nw_src=192.168.0.1,nw_dst=192.168.0.6 actions=output:1"
    # flow check: sw1: reverse (host2,3,5,6 -> host1)
    And sw1 should have a flow entry like "dl_dst=00:00:00:01:00:01,nw_dst=192.168.0.1 actions=output:2"
    # flow check: sw2: forward (host1 -> host2)
    And sw2 should have a flow entry like "dl_dst=00:00:00:01:00:02,nw_dst=192.168.0.2 actions=output:2"
    # flow check: sw2: reverse (host2 -> host1)
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:3"
    # flow check: sw3: forward (host1 -> host3)
    And sw3 should have a flow entry like "dl_dst=00:00:00:01:00:03,nw_dst=192.168.0.3 actions=output:1"
    # flow check: sw3: reverse (host3 -> host1)
    And sw3 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:3"
    # flow check: sw4: forward (host1 -> host3,5,6)
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:1"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:05,nw_src=192.168.0.1,nw_dst=192.168.0.5 actions=output:1"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:06,nw_src=192.168.0.1,nw_dst=192.168.0.6 actions=output:3"
    # flow check: sw4: reverse (host3,5,6 -> host1)
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:2"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:05,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.5,nw_dst=192.168.0.1 actions=output:2"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:06,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.6,nw_dst=192.168.0.1 actions=output:2"
    # flow check: sw5: forward (host1 -> host3,5)
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:4"
    And sw5 should have a flow entry like "dl_dst=00:00:00:01:00:05,nw_dst=192.168.0.5 actions=output:1"
    # flow check: sw5: forward (host3,5 -> host1)
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:3"
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:05,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.5,nw_dst=192.168.0.1 actions=output:3"
    # flow check: sw6: forward (host1 -> host6)
    And sw6 should have a flow entry like "dl_dst=00:00:00:01:00:06,nw_dst=192.168.0.6 actions=output:1"
    # flow check: sw6: reverse (host6 -> host1)
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:06,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.6,nw_dst=192.168.0.1 actions=output:3"

    When I say "Step.7: connection check with recovered topology: topology_B"
    And I send 2 times 1 packet bidirectionally host1 and host2
    And I send 2 times 1 packet bidirectionally host1 and host3
    And I send 2 times 1 packet bidirectionally host1 and host5
    And I send 2 times 1 packet bidirectionally host1 and host6
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host5 | host6 |
      |    32 |     8 |     8 |     8 |     8 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host5 | host6 |
      |    32 |     8 |     8 |     8 |     8 |

    When I say "Step.8: recover link between sw2-sw3, change topology_B to topology_A"
    And I turn up port 1 on switch sw2
    # flow check: sw1: forward (host1 -> host2,3,5,6)
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:3"
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:3"
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:05,nw_src=192.168.0.1,nw_dst=192.168.0.5 actions=output:1"
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:06,nw_src=192.168.0.1,nw_dst=192.168.0.6 actions=output:1"
    # flow check: sw1: reverse (host2,3,5,6 -> host1)
    And sw1 should have a flow entry like "dl_dst=00:00:00:01:00:01,nw_dst=192.168.0.1 actions=output:2"
    # flow check: sw2: forward (host1 -> host2,3)
    And sw2 should have a flow entry like "dl_dst=00:00:00:01:00:02,nw_dst=192.168.0.2 actions=output:2"
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:1"
    # flow check: sw2: reverse (host2,3 -> host1)
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:3"
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:3"
    # flow check: sw3: forward (host1 -> host3)
    And sw3 should have a flow entry like "dl_dst=00:00:00:01:00:03,nw_dst=192.168.0.3 actions=output:1"
    # flow check: sw3: reverse (host3 -> host1)
    And sw3 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:2"
    # flow check: sw4: forward (host1 -> host5,6)
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:05,nw_src=192.168.0.1,nw_dst=192.168.0.5 actions=output:1"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:06,nw_src=192.168.0.1,nw_dst=192.168.0.6 actions=output:3"
    # flow check: sw4: reverse (host5,6 -> host1)
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:05,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.5,nw_dst=192.168.0.1 actions=output:2"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:06,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.6,nw_dst=192.168.0.1 actions=output:2"

    When I say "Step.9: connection check with recovered topology: topology_A"
    And I send 2 times 1 packet bidirectionally host1 and host2
    And I send 2 times 1 packet bidirectionally host1 and host3
    And I send 2 times 1 packet bidirectionally host1 and host5
    And I send 2 times 1 packet bidirectionally host1 and host6
    Then the total number of tx packets should be:
      | host1 | host2 | host3 | host5 | host6 |
      |    40 |    10 |    10 |    10 |    10 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 | host5 | host6 |
      |    40 |    10 |    10 |    10 |    10 |
