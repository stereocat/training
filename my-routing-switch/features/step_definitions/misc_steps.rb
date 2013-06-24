When /^wait until "([^"]*)" is up$/ do | process |
  nloop = 0
  pid_file = File.join( Trema.pid, "#{ process }.pid" )
  loop do
    nloop += 1
    raise "Timeout" if nloop > 60  # FIXME
    break if FileTest.exists?( pid_file ) and not ps_entry_of( process ).nil?
    sleep 0.1
  end
  sleep 1  # FIXME
end


When /^\*\*\* sleep (\d+) \*\*\*$/ do | sec |
  sleep sec.to_i
end

When /^I say "(.+)"$/ do | message |
  true
end
