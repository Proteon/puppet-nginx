# nginx_version.rb

Facter.add("nginxversion") do
	setcode do
		Facter::Util::Resolution.exec('/usr/bin/dpkg-query -W -f=\'${Version}\' nginx-common 2>/dev/null')
	end
end
