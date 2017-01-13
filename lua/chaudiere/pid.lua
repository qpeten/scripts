#!/usr/bin/lua

-- Dependencies :
--	- jq
--	- domoticz (obviously)

array = {} --Le nom doit être exactement le même que dans Domoticz
array["Ch Quentin"] = {["idxTemp"] = 53, ["idxKp"] = 8, ["idxKi"] = 9, ["idxKd"] = 10}
array["Salon"] = {["idxTemp"] = 55, ["idxKp"] = 11, ["idxKi"] = 12, ["idxKd"] = 12}


OUTMIN = 0
OUTMAX = 100
SAMPLE_TIME_SEC = 5*60
START_TIME = 50

PI_IP = "127.0.0.1"

--function getZoneNames()
--	array = explode(' Consigne ', os.capture('curl -s "http://' .. PI_IP .. '/json.htm?type=devices&filter=utility&used=true&order=Name"| grep \'"Name\' | grep Consigne | cut -d \'"\' -f 4', false))
--	array[1] = string.sub(array[1], 10) --Permet de virer le 'Consigne ' qui reste dans le premier element de l'array
--end

function getBeginInfo()
	for arrName,arrValue in pairs(array) do
		array[arrName]["output"] = "ChauffageP-" .. arrName
		array[arrName]["iTerm"] = START_VALUE
		array[arrName]["lastInput"] = getTemp(array[arrName]["idxTemp"])
	end
end

function getUserVar(idx)
	return os.capture('curl -s "http://127.0.0.1/json.htm?type=command&param=getuservariable&idx=' .. idx .. '" | grep \'"Temp\' | cut -d ":" -f 2 | cut -d "," -f 1 | cut -d " " -f 2')
end

function getTemp(idx)
	return tonumber(os.capture('curl -s "http://127.0.0.1/json.htm?type=devices&rid=' .. idx .. '" | grep \'"Temp\' | grep -v Type | cut -d ":" -f 2 | cut -d "," -f 1 | cut -d " " -f 2'))
end

function getInfo()
	for arrName, arrValue in pairs(array) do
		local Kp = tonumber(getUserVar(array[arrName]["idxKp"]))
		local Ki = tonumber(getUserVar(array[arrName]["idxKi"]))
		local Kd = tonumber(getUserVar(array[arrName]["idxKd"]))
		print(Kp)
		if array[arrName]["Kp"] == nil then --Initialization
			array[arrName]["Kp"] = Kp
			array[arrName]["Ki"] = Ki
			array[arrName]["Kd"] = Kd
		elseif ((array[arrName]["Kp"] ~= Kp) and (array[arrName]["Ki"] ~= Ki) and (array[arrName]["Kd"] ~= Kd)) then 
--If we change value when the PID is running
		�--	array[arrName]["Kp"] = Kp
			array[arrName]["Ki"] = Ki * SAMPLE_TIME_SEC
			array[arrName]["Kd"] = Kd / SAMPLE_TIME_SEC
		end
	end
end

function explode(div,str)
    if (div=='') then return false end
    local pos,arr = 0,{}
    for st,sp in function() return string.find(str,div,pos,true) end do
        table.insert(arr,string.sub(str,pos,st-1))
        pos = sp + 1
    end
    table.insert(arr,string.sub(str,pos))
    return arr
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

getBeginInfo()
getInfo()
print(array["Ch Quentin"]["Kp"])

