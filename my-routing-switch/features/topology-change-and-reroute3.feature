Feature: topology change detection and re-routing test No.1

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
      link "sw1", "sw2"
      link "sw2", "sw3"
      link "sw3", "sw4"
      link "sw1", "sw5"
      link "sw5", "sw6"
      link "sw6", "sw7"
      link "sw7", "sw4"
      link "host1", "sw1"
      link "host2", "sw4"
      link "host3", "sw7"
      """
    When I run `trema run ../../my-routing-switch.rb -c routing-switch.conf -d`
    And wait until "MyRoutingSwitch" is up
    And *** sleep 10 ***

  Scenario: Topology change by link down/up and flow_mod to re-routing
    ## initial
    When I send 2 times 1 packet bidirectionally host1 and host2
    And I send 2 times 1 packet bidirectionally host1 and host3
    Then the total number of tx packets should be:
      | host1 | host2 | host3 |
      |     4 |     2 |     2 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 |
      |     4 |     2 |     2 |
    # flow check: sw1-sw7: forward (host1 -> host2)
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:2"
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:1"
    And sw3 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:2"
    # flow check: sw1-sw7: forward (host2 -> host1)
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:2"
    And sw3 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"
    # flow check: sw1-sw7: forward (host1 -> host3)
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:3"
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:1"
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:2"
    # flow check: sw1-sw7: reverse (host3 -> host1)
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:2"
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:1"
    And sw7 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:2"
    # last hop
    And sw1 should have a flow entry like "dl_dst=00:00:00:01:00:01,nw_dst=192.168.0.1 actions=output:1"
    And sw4 should have a flow entry like "dl_dst=00:00:00:01:00:02,nw_dst=192.168.0.2 actions=output:2"
    And sw7 should have a flow entry like "dl_dst=00:00:00:01:00:03,nw_dst=192.168.0.3 actions=output:3"

    # topology change occured by linkdown
    When I turn down port 1 on switch sw2
    # flow check: sw1-sw7: forward (host1 -> host2)
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:2"
    And sw2 should not have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:1"
    And sw3 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:2"
    # flow check: sw1-sw7: forward (host2 -> host1)
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:2"
    And sw3 should not have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"

    # send packets again
    When I send 2 times 1 packet bidirectionally host1 and host2
    And I send 2 times 1 packet bidirectionally host1 and host3
    Then the total number of tx packets should be:
      | host1 | host2 | host3 |
      |     8 |     4 |     4 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 |
      |     8 |     4 |     4 |
    # flow check: sw1-sw7: forward (host1 -> host2)
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:3"
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:1"
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:2"
    And sw7 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:1"
    # flow check: sw1-sw7: forward (host2 -> host1)
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:3"
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:2"
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"
    And sw7 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:2"
    # flow check: sw1-sw7: forward (host1 -> host3)
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:3"
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:1"
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:2"
    # flow check: sw1-sw7: reverse (host3 -> host1)
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:2"
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:1"
    And sw7 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:2"
    # last hop
    And sw1 should have a flow entry like "dl_dst=00:00:00:01:00:01,nw_dst=192.168.0.1 actions=output:1"
    And sw4 should have a flow entry like "dl_dst=00:00:00:01:00:02,nw_dst=192.168.0.2 actions=output:2"
    And sw7 should have a flow entry like "dl_dst=00:00:00:01:00:03,nw_dst=192.168.0.3 actions=output:3"

    # topology change occured by linkup
    When I turn up port 1 on switch sw2
    # flow check: sw1-sw7: forward (host1 -> host2)
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:2"
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:1"
    And sw3 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:02,nw_src=192.168.0.1,nw_dst=192.168.0.2 actions=output:2"
    # flow check: sw1-sw7: forward (host2 -> host1)
    And sw2 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:2"
    And sw3 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"
    And sw4 should have a flow entry like "dl_src=00:00:00:01:00:02,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.2,nw_dst=192.168.0.1 actions=output:1"
    # flow check: sw1-sw7: forward (host1 -> host3)
    And sw1 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:3"
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:1"
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:01,dl_dst=00:00:00:01:00:03,nw_src=192.168.0.1,nw_dst=192.168.0.3 actions=output:2"
    # flow check: sw1-sw7: reverse (host3 -> host1)
    And sw5 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:2"
    And sw6 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:1"
    And sw7 should have a flow entry like "dl_src=00:00:00:01:00:03,dl_dst=00:00:00:01:00:01,nw_src=192.168.0.3,nw_dst=192.168.0.1 actions=output:2"
    # last hop
    And sw1 should have a flow entry like "dl_dst=00:00:00:01:00:01,nw_dst=192.168.0.1 actions=output:1"
    And sw4 should have a flow entry like "dl_dst=00:00:00:01:00:02,nw_dst=192.168.0.2 actions=output:2"
    And sw7 should have a flow entry like "dl_dst=00:00:00:01:00:03,nw_dst=192.168.0.3 actions=output:3"

    # send packets again
    When I send 2 times 1 packet bidirectionally host1 and host2
    And I send 2 times 1 packet bidirectionally host1 and host3
    Then the total number of tx packets should be:
      | host1 | host2 | host3 |
      |    12 |     6 |     6 |
    And the total number of rx packets should be:
      | host1 | host2 | host3 |
      |    12 |     6 |     6 |
