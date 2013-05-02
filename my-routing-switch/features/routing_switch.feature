Feature: control multiple openflow switchies using routing_switch

  As a Trema user
  I want to control multiple openflow switches using routing_switch application
  So that I can send and receive packets


  @slow_process
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
    When I run `trema send_packets --source host1 --dest host2`
    And I run `trema send_packets --source host2 --dest host1`
    And I run `trema send_packets --source host1 --dest host2 --duration 10`
    And I run `trema show_stats host1 --rx`
    And I run `trema show_stats host2 --rx`
    Then the output from "trema show_stats host1 --rx" should contain exactly:
    """
    ip_dst,tp_dst,ip_src,tp_src,n_pkts,n_octets
    192.168.0.1,1,192.168.0.2,1,1,50

    """
    And the output from "trema show_stats host2 --rx" should contain exactly:
    """
    ip_dst,tp_dst,ip_src,tp_src,n_pkts,n_octets
    192.168.0.2,1,192.168.0.1,1,10,500

    """
