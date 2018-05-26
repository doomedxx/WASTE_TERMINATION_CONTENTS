--[[
  Title:      Shared crap
--]]


Crap = {

  -- run a command.
  -- return: error code, command output
  Run = function(command)
    local retcode = 0
    local output = nil 
    local log = os.tmpname()
    
    retcode = os.execute(command..' > '..log..' 2>&1 ')

    local f = io.open(log, "r")
    if f then output = f:read("*a"); f:close() end
    os.remove(log)
    
    return retcode, output
  end
  ,
  
}
