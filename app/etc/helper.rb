def scanQue
  if $scanQue
    $scanQue
  else
    $scanQue = Dispatch::Queue.new('jmpr.scan')
  end
end
