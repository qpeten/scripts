#!/usr/bin/lua

PI_IP = "127.0.0.1"
gpioPinTDown = 2
gpioPinTUp = 0

idxCons = 37	-- Idx containing the target watertemperature
idxTemp = 28 	-- Idx of the thermometer
gpioOn = 1
gpioOff = 0

function change3Voies(direction)
    if direction == 1 then
    	print('up')
        os.execute("gpio write " .. gpioPinTUp .. " " .. gpioOn) 
        os.execute("gpio write " .. gpioPinTDown .. " " .. gpioOff)
    elseif direction  == -1 then
        print('down')
        os.execute("gpio write " .. gpioPinTUp .. " " .. gpioOff)
        os.execute("gpio write " .. gpioPinTDown .. " " .. gpioOn)
    else
        print('STOP')
        os.execute("gpio write " .. gpioPinTUp .. " " .. gpioOn)
        os.execute("gpio write " .. gpioPinTDown .. " " .. gpioOn)
    end
end

function sleep(n)
    os.execute("sleep " .. tonumber(n))
end

function getTemp(idx)
    return tonumber(os.capture('curl -s "http://' .. PI_IP .. '/json.htm?type=devices&rid=' .. idx .. '" | grep \'"Temp\' | grep -v Type | cut -d ":" -f 2 | cut -d "," -f 1 | cut -d " " -f 2'))
end

function getCons(idx)
    return tonumber(os.capture('curl -s "http://' .. PI_IP .. '/json.htm?type=devices&rid=' .. idx .. '" | grep \'"SetPoint\' | grep -v SubType | cut -d ":" -f 2 | cut -d "," -f 1 | cut -d " " -f 2 | cut -d \'"\' -f 2'))
end

function os.capture(cmd, raw)
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*a'))
    f:close()
    if raw then return s end 
    s = string.gsub(s, '^%s+', '') 
    s = string.gsub(s, '%s+$', '') 
    s = string.gsub(s, '[\n\r]+', ' ') 
    return s
end 

-- Initialization
change3Voies(-1)
sleep(3)
oldConsigne = -1
consigne = -1
waitNextConsigne = false

while true do
    oldConsigne = consigne
    consigne = getCons(idxCons)
    temp = getTemp(idxTemp)
--    print(consigne)
--    print(temp)
    
    if (consigne ~= oldConsigne) then
        goFast = true
    end
    if waitNextConsigne and goFast == false then
        sleep(30)
        temp = consigne --On passe ce cycle
    end
    
    if temp < consigne then
    	change3Voies(1)
    elseif temp > consigne then
    	change3Voies(-1)
    end
    
    
    if goFast then
    	waitNextConsigne = false
        i=0
        if temp < consigne then
    	    while getTemp(idxTemp) <= consigne do
               sleep(8)
               i=i+1
               if i >= 18 then
                   break
               end
       	    end
       	else
       	    while getTemp(idxTemp) >= consigne do
       	       sleep(8)
       	       i=i+1
       	       if i >=18 then
       	           waitNextConsigne = true
       	           break
       	       end
       	    end
       	end
        change3Voies(0)
        goFast = false
    else
    	sleep(3)
    	change3Voies(0)
    	sleep(6)
    end
end
