function PulsarLib.GetRank(ply)
	if ply.GetSecondaryUserGroup then
		local rank = ply:GetSecondaryUserGroup()
		if rank == "user" then rank = ply:GetUserGroup() end
		if rank == "" then rank = ply:GetUserGroup() end
		if rank == " " then rank = ply:GetUserGroup() end
		return rank
	else
		return ply:GetUserGroup()
	end
end