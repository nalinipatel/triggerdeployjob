# Class : triggerdeployjob::params
# Description: Stores parameters
class triggerdeployjob::params {
  $joblist     = hiera_hash("triggerdeployjob::joblist_${fact_servertype}",'UNDEF')
}
