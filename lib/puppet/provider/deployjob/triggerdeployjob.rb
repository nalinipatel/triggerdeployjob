# Custom Provider for custom resource type: deployjob
# Represents set of actions that can be executed on the custom resource type.

require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require 'logger'

Puppet::Type.type(:deployjob).provide(:ruby) do
  ### Logger
  mylogger = Logger.new('/var/log/triggerbamboodeploy.log', 'monthly')
  mylogger.datetime_format = '%Y-%m-%d %H:%M:%S'

  ### Define the deploy log-file location
  def deploy_log
    "%s%s.log" %["/tmp/deploy_", resource[:envjobid]]
  end

  ### Define the deploy-trigger URI
  def get_trigger_uri(relVersion)
    # @todo : Store the URI in hiera as default value and just find and replace the EnvId,Release Version here
    "%s%s%s%s" %["http://bamboo/deploy/executeManualDeployment.action?environmentId=",resource[:envjobid],"&releaseTypeOption=PROMOTE&promoteVersion=",relVersion]
  end

  ### Defined the deploy-job-result URI
  def get_result_uri	
    # 12345678 - sample Env Id of Deploy Job, get it from bamboo UI.
    # @todo : Store the URI in hiera as default value and just find and replace the Release Version here
    "%s%s%s" %["http://bamboo/rest/api/latest/deploy/environment/",resource[:envjobid],"/results"]
  end

  def get_proxy_uri	
    env = `hostname | awk -F "-" '{print $2}' | cut -c1-3`.strip
    puts('[Get_Proxy_URI] Current Env = '+env)
    mylogger.debug("[Get_Proxy_URI] Current Env = "+env)
    case env
    when "dev","int","tst"
        proxyenv = "dev"
    else
        proxyenv = env
    end
    puts('[Get_Proxy_URI] FWD PROXY = mypxy-'+proxyenv+'.com.au') 
    mylogger.debug("[Get_Proxy_URI] FWD PROXY = mypxy-"+proxyenv+".com.au") 
    "%s%s%s" %["mypxy-",proxyenv,".com.au"]
  end

  def trigger_deploy(relVersion)
      trig_uri = URI(get_trigger_uri(relVersion))
      puts "[Trigger_Deploy] Bamboo Deploy Job URI = #{trig_uri}"
      mylogger.debug("[Trigger_Deploy] Bamboo Deploy Job URI = #{trig_uri}")

      httpreq = Net::HTTP::Post.new(trig_uri.request_uri)
      puts "[Trigger_Deploy] Created httpreq obj"
      mylogger.debug("[Trigger_Deploy] Created httpreq obj")

      httpreq.basic_auth(resource[:bamboouser],resource[:bamboopass])
      puts "[Trigger_Deploy] Assigned user creds"
      mylogger.debug("[Trigger_Deploy] Assigned user creds")

      proxy = Net::HTTP::Proxy(get_proxy_uri,'3128')

      httpres = proxy.start(trig_uri.hostname, trig_uri.port, :use_ssl => true) do |http|
        http.request(httpreq)
      end
      
      puts "[Trigger_Deploy] HTTP Req Sent"
      mylogger.debug("[Trigger_Deploy] HTTP Req Sent")

      case httpres
         when Net::HTTPSuccess, Net::HTTPRedirection
            puts "[Trigger_Deploy] HTTP Code: OK"
            mylogger.debug("[Trigger_Deploy] HTTP Code: OK")
         else
            puts "[Trigger_Deploy] HTTP Error Code: #{httpres.value}"
            mylogger.error("[Trigger_Deploy] HTTP Error Code: #{httpres.value}")
      end
  end

  def get_result(relVersion)
    sleep_secs = 60
    puts get_result_uri

    resURI = URI.parse(get_result_uri)
    resultFile = deploy_log
    httpConn = Net::HTTP.new(resURI.host,resURI.port)
    httpReq = Net::HTTP::Get.new(resURI.request_uri)
    httpReq.basic_auth(resource[:bamboouser],resource[:bamboopass])

    jobStatus = "RUNNING OR NOT TRIGGERED"
    jobResult = "PENDING"

    # Try for 10 minutes to get the result of job before quitting
    for counter in 1..10
        # Send Request and Get HTTP Response
          httpResponse = httpConn.request(httpReq)
          jsonHash = JSON.parse(httpResponse.body) # returns a hash
          jobStatus = jsonHash["results"][0]["lifeCycleState"]
          jobResult = jsonHash["results"][0]["deploymentState"]

          if jobStatus == "FINISHED" then
            puts "[Get_Result] ATTEMPT - #{counter} deploy job finished, logging to file : #{jobStatus} , #{jobResult}"
            mylogger.debug("[Get_Result] ATTEMPT - #{counter} deploy job finished, logging to file : #{jobStatus} , #{jobResult}")
            break;
          else
            # sleep and re-try
            puts "[Get_Result] ATTEMPT - #{counter} deploy job not finished, sleeping for #{sleep_secs} secs"
            mylogger.debug("[Get_Result] ATTEMPT - #{counter} deploy job not finished, sleeping for #{sleep_secs} secs")
            sleep(sleep_secs)
          end
    end
    puts('[Get_Result] status='+jobStatus)
    puts('[Get_Result] result='+jobResult)
    mylogger.debug("[Get_Result] status="+jobStatus+", result="+jobStatus)

    # Save the output to file
    File.open(resultFile,"w+") do |resfile|
        resfile.puts('env-id='+resource[:envjobid])
        resfile.puts('release-version='+relVersion)
        resfile.puts('status='+jobStatus)
        resfile.puts('result='+jobResult)
    end
  end


  def get_last_stable_version

    resURI = URI.parse(get_result_uri)
    httpConn = Net::HTTP.new(resURI.host,resURI.port)
    httpReq = Net::HTTP::Get.new(resURI.request_uri)
    httpReq.basic_auth(resource[:bamboouser],resource[:bamboopass])

    # Send Request and Get HTTP Response
    httpResponse = httpConn.request(httpReq)
    jsonHash = JSON.parse(httpResponse.body) # returns a hash
    puts ('[Get_Last_Stable_Version] isFinished = '+jsonHash["results"][0]["lifeCycleState"])
    puts ('[Get_Last_Stable_Version] id = '+jsonHash["results"][0]["deploymentVersion"]["name"])
    mylogger.debug('[Get_Last_Stable_Version] isFinished = '+jsonHash["results"][0]["lifeCycleState"])
    mylogger.debug('[Get_Last_Stable_Version] deployment-id = '+jsonHash["results"][0]["deploymentVersion"]["name"])

    lastVersion = jsonHash["results"][0]["deploymentVersion"]["name"]
    puts ('[Get_Last_Stable_Version] : version ='+lastVersion)
    mylogger.debug('[Get_Last_Stable_Version] : version ='+lastVersion)
    "%s" %[lastVersion]
  end

  def exists?
    File.exist? deploy_log
  end

  def create
    # PRE-TRIGGER VERSION CHECKS
    if resource[:version] == "last-stable" then
      # Grab the last stable release version deployed in this env
      puts ('[TriggerDeployJob] Fetching last stable version from bamboo api')
      mylogger.debug('[TriggerDeployJob] Fetching last stable version from bamboo api')
      relVersion = get_last_stable_version
    else
      relVersion = resource[:version]
    end
    puts "[TriggerDeployJob] Last Stable/Received Release Version = #{relVersion}"
    mylogger.debug("[TriggerDeployJob] Last Stable/Received Release Version = "+relVersion)
    # 1. invoke function trigger_deploy
    trigger_deploy(relVersion)

    puts "[TriggerDeployJob] Triggered Deploy, Now fetching result..."
    mylogger.debug("[TriggerDeployJob] Triggered Deploy, Now fetching result...")
    # 2. get result of the deploy job
    get_result(relVersion)
  end

  def destroy
  end

end
