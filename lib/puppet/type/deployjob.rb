# custom type: deployjob 
# represents a bamboo deploy plan which deploys applications/artifacts
Puppet::Type.newtype(:deployjob) do
  @doc = "Creates a new (bamboo)deploy-job resource type"
  ## define properties here

  ## define parameters here
  
  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:envjobid, :namevar => true) do
    desc "The env-id/job-key for the deploy job/build job"
  end

  newparam(:jobtype) do
    desc "The type of job can be build or deploy"
    defaultto :"deploy"
  end

  newparam(:version) do
    desc "The release version to be deployed"
    defaultto :"0.0.0"
  end

  newparam(:planname) do
    desc "Name of build job"
    defaultto :"bambooplan"
  end

  newparam(:bamboouser) do
    desc "Bamboo username"
    defaultto :"bamboo.user"
  end

  newparam(:bamboopass) do
    desc "Bamboo user password"
    defaultto :"******"
  end

end
