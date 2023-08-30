if CLIENT then
    function PulsarLib.Notify(msg, len)
        notification.AddLegacy(msg, NOTIFY_GENERIC, len)
    end

    net.Receive("PulsarLib.Notify", function()
        local msg = net.ReadString()
        local len = net.ReadUInt(8)
        PulsarLib.Notify(msg, len)
    end)
end

if SERVER then
    util.AddNetworkString("PulsarLib.Notify")

    function PulsarLib.Notify(ply, msg, length)
        net.Start("PulsarLib.Notify")
        net.WriteString(msg)
        net.WriteUInt(length, 8)

        if ply then
            net.Send(ply)
        else
            net.Broadcast()
        end
    end
end