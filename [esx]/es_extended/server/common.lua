ESX = {}
ESX.Players = {}
ESX.Jobs = {}
ESX.Items = {}
Core = {}
Core.UsableItemsCallbacks = {}
Core.ServerCallbacks = {}
Core.TimeoutCount = -1
Core.CancelledTimeouts = {}
Core.RegisteredCommands = {}
Core.Pickups = {}
Core.PickupId = 0

AddEventHandler('esx:getSharedObject', function(cb)
	cb(ESX)
end)

exports('getSharedObject', function()
	return ESX
end)

local function StartDBSync()
	CreateThread(function()
		while true do
			Wait(10 * 60 * 1000)
			Core.SavePlayers()
		end
	end)
end

MySQL.ready(function()
	MySQL.query('SELECT * FROM items', {}, function(result)
		for k,v in ipairs(result) do
			ESX.Items[v.name] = {
				label = v.label,
				weight = v.weight,
				rare = v.rare,
				canRemove = v.can_remove
			}
		end
	end)

	local Jobs = {}
	MySQL.query('SELECT * FROM jobs', {}, function(jobs)
		for k,v in ipairs(jobs) do
			Jobs[v.name] = v
			Jobs[v.name].grades = {}
		end

		MySQL.query('SELECT * FROM job_grades', {}, function(jobGrades)
			for k,v in ipairs(jobGrades) do
				if Jobs[v.job_name] then
					Jobs[v.job_name].grades[tostring(v.grade)] = v
				else
					print(('[^3WARNING^7] Ignoring job grades for ^5"%s"^0 due to missing job'):format(v.job_name))
				end
			end

			for k2,v2 in pairs(Jobs) do
				if ESX.Table.SizeOf(v2.grades) == 0 then
					Jobs[v2.name] = nil
					print(('[^3WARNING^7] Ignoring job ^5"%s"^0due to no job grades found'):format(v2.name))
				end
			end
			ESX.Jobs = Jobs
			print('[^2INFO^7] ESX ^5Legacy^0 initialized')
			StartDBSync()
			StartPayCheck()
		end)
	end)
end)

RegisterServerEvent('esx:clientLog')
AddEventHandler('esx:clientLog', function(msg)
	if Config.EnableDebug then
		print(('[^2TRACE^7] %s^7'):format(msg))
	end
end)

RegisterServerEvent('esx:triggerServerCallback')
AddEventHandler('esx:triggerServerCallback', function(name, requestId, ...)
	local playerId = source

	ESX.TriggerServerCallback(name, requestId, playerId, function(...)
		TriggerClientEvent('esx:serverCallback', playerId, requestId, ...)
	end, ...)
end)
