local M		= {}
local dns	= require "dns"

function M.cached_ko ()
	return ngx.shared.dnsbl_cache:get(ngx.var.remote_addr) == "ko"
end

function M.cached ()
	return ngx.shared.dnsbl_cache:get(ngx.var.remote_addr) ~= nil
end

function M.check (dnsbls, resolvers)
	local rip = dns.ip_to_arpa()
	for k, v in ipairs(dnsbls) do
		local req = rip .. "." .. v
		local ips = dns.get_ips(req, resolvers)
		for k2, v2 in ipairs(ips) do
			local a,b,c,d = v2:match("([%d]+).([%d]+).([%d]+).([%d]+)")
			if a == "127" then
				ngx.shared.dnsbl_cache:set(ngx.var.remote_addr, "ko", 86400)
				ngx.log(ngx.NOTICE, "ip " .. ngx.var.remote_addr .. " is in DNSBL " .. v)
				return true
			end
		end
	end
	ngx.shared.dnsbl_cache:set(ngx.var.remote_addr, "ok", 86400)
	return false
end

return M
