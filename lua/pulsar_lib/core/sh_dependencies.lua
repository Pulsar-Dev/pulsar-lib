PulsarLib = PulsarLib or {}
PulsarLib.Dependency = PulsarLib.Dependency or setmetatable({
	stored = {}
}, {__index = PulsarLib})


function PulsarLib.Dependency.Loaded(dependency)
	PulsarLib.Logging.Debug("Dependency loaded: " .. dependency)
	if not PulsarLib.Addons or not PulsarLib.Addons.WaitingForDeps then return end
	for k, v in pairs(PulsarLib.Addons.WaitingForDeps) do
		for k2, v2 in pairs(v.Dependencies) do
			if k2 == dependency then
				PulsarLib.Addons.WaitingForDeps[k2] = nil

				v:Load()
			end
		end
	end
end