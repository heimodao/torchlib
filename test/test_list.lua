local torchlib = require 'torchlib'

local TestList = {}
local tester


function testList(l)
  tester:asserteq(0, l:size())
  l:add(10)
  tester:asserteq(1, l:size())
  tester:asserteq(10, l:get(1))
  l:add(7, 1)
  tester:asserteq(2, l:size())
  tester:asserteq(10, l:get(2))
  tester:asserteq(7, l:get(1))
  v = l:remove(1)
  tester:asserteq(7, v)
  tester:asserteq(1, l:size())
  tester:asserteq(10, l:get(1))

  l:addTable({1, 3, 2, 4})
  tester:asserteq(5, l:size())
  tester:asserteq(1, l:get(2))
  tester:asserteq(3, l:get(3))
  tester:asserteq(2, l:get(4))
  tester:asserteq(4, l:get(5))

  tester:asserteq(true, l:contains(3))
  tester:asserteq(false, l:contains(0))
end


function TestList.testArray()
  local l = ArrayList.new()
  testList(l)
end

function TestList.testLinkedList()
  local l = LinkedList.new()
  testList(l)
end


tester = torch.Tester()
tester:add(TestList)
tester:run()