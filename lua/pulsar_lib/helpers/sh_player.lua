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