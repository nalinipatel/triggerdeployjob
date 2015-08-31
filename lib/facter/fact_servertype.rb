# fact_servertype.rb
# Description : 
#   Custom fact to fetch the type/role of server like iamsec,depcdp,appnep,esbnep,appmdw
Facter.add('fact_servertype') do
  setcode do
    Facter::Core::Execution::exec('/bin/hostname | awk -F "-" \'{print $1}\'')
  end
end
