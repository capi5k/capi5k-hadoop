def role_hadoop_master 
  $myxp.role_with_name('capi5k-init').servers.first
end

def role_hadoop_slaves
  $myxp.role_with_name('capi5k-init').servers.slice(1..-1)
end

def file_core_site
  "#{hadoop_path}/templates/core-site.xml.erb"
end

def file_mapred_site
  "#{hadoop_path}/templates/mapred-site.xml.erb"
end

