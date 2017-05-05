#!/usr/bin/lua

PI_IP = "192.168.1.30"
gpioPinActivate = 0
gpioPinDirection = 2

idxCons = 37	-- Idx containing the target water temperature
idxTemp = 28 	-- Idx of the thermometer
gpioPinActivateOn = 1
gpioPinActivateOff = 0
gpioPinDirectionUp = 0
gpioPinDirectionDown = 1

function change3Voies(direction)
    if direction == 1 then
        os.execute("gpio write " .. gpioPinDirection .. " " .. gpioPinDirectionUp)
        os.execute("gpio write " .. gpioPinActivate .. " " .. gpioPinActivateOn)
    elseif direction  == -1 then
        os.execute("gpio write " .. gpioPinDirection .. " " .. gpioPinDirectionDown)
        os.execute("gpio write " .. gpioPinActivate .. " " .. gpioPinActivateOn)
    else
        os.execute("gpio write " .. gpioPinActivate .. " " .. gpioPinActivateOff)
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
    if (temp == nil or consigne == nil) then
    	change3Voies(-1);
    	print(os.date("%x %X") .. " temp or consigne == nil. Waiting 60sec.");
    	sleep(60);
    	break;
    end
    print(os.date("%x %X") .. " C:" .. consigne .. " T:" .. temp)
        
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

