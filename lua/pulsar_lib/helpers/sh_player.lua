function PulsarLib.GetRank(ply, secondary)
	secondary = secondary or false
	return !secondary and ply:GetUserGroup() or ply:GetSeccondaryUserGroup()
end