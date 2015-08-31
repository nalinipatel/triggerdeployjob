# === Class: triggerdeployjob
#
# === Description:
### Triggers the bamboo plans as configured in hiera
#
# === Actions:
#
# === Parameters:
#  $joblist_{ServerType} : Hash of arrays of bamboo deploy jobs to be triggered
#  This must be defined in hiera => 
#  triggerdeployjob::joblist_{ServerType}
#    Your-Deploy-Job-Key:
#      plan_name:  (Optional your plan name like "Deploy My API")
#      jobtype: (Optional your job type i.e. deploy OR build)
#      version: (Version of release to be deployed) 
### See examples below: 
#
# === Variables:
#
# === Examples:
### Hiera Definitions
#  triggerdeployjob::joblist_myWebApp:
#    <EnvId like 59000012>:
#      jobtype: 'deploy'
#      version: '1.0.1' OR 'last-stable'
#
### Puppet Include
# class { triggerdeployjob : }
#
# === Authors
#
# Nalini Patel nalinidpatel@yahoo.com
#
#
class triggerdeployjob inherits triggerdeployjob::params{

  notify {"Server Type = ${fact_servertype}": } ->
  notify {'See detailed logs in /var/log/triggerbamboodeploy.log': }

  if $joblist != 'UNDEF' {
    create_resources('deployjob', $joblist)
  }
  else {
    notify{ "Not found triggerdeployjob::joblist_${fact_servertype} in hiera, so skipping deployment": }
  }
}
