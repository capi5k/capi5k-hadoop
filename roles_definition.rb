role :hadoop_master do
  role_hadoop_master
end

role :hadoop_slaves do
  role_hadoop_slaves
end

role :hadoop do
  master = role_hadoop_master
  if (master.respond_to?('each'))
    role_hadoop_master + role_hadoop_slaves
  else
    slaves = role_hadoop_slaves
    slaves << master
    slaves
  end
end

