---@diagnostic disable: undefined-field
--- Get the rank or secondary rank of a player
--- @param ply Player The player to get the rank of.
--- @param secondaryUserGroup? boolean Whether to get the secondary user group instead of the primary user group.
--- @return string
function PulsarLib.GetRank(ply, secondaryUserGroup)
	if ply.GetSecondaryUserGroup and secondaryUserGroup then
		local rank = ply:GetSecondaryUserGroup()
		if rank == "user" then rank = ply:GetUserGroup() end
		if rank == "" then rank = ply:GetUserGroup() end
		if rank == " " then rank = ply:GetUserGroup() end
		return rank
	else
		return ply:GetUserGroup()
	end
end