set :hadoop_path, "./"

load "#{hadoop_path}/roles.rb"
load "#{hadoop_path}/roles_definition.rb"
load "#{hadoop_path}/output.rb"

set :tarball_url, "http://www.eu.apache.org/dist/hadoop/common/hadoop-1.2.1/hadoop-1.2.1.tar.gz"
set :tarball_destination, "/opt/hadoop"
set :wget, "http_proxy=http://proxy:3128 https_proxy=http://proxy:3128 wget"
set :tmp_dir, "./tmp"
set :file_mapred_site, "#{file_mapred_site}"
set :file_core_site, "#{file_core_site}"

def first_master
  master = role_hadoop_master
  if master.respond_to?('first')
    master =  master.first  
  end
  master
end


namespace :hadoop do

  desc 'Install hadoop on nodes'
  task :default do
    prepare::default
    configure::default
  end

  namespace :prepare do

    desc 'Prepare nodes'
    task 'default' do
      install
      packages
      permissions
    end


    desc 'Download tarball'
    task :install, :roles => [:hadoop] do
      set :user, "root"
      run "mkdir -p #{tarball_destination}"
      run "#{wget} #{tarball_url} -O #{tarball_destination}/hadoop.tar.gz 2>1"
      run "cd #{tarball_destination} && tar -xvzf hadoop.tar.gz"
    end


    desc 'Install extra pacakges'
    task :packages, :roles => [:hadoop] do
      set :user, "root"
      run "apt-get update"
      run "apt-get install -y openjdk-7-jre openjdk-7-jdk"
    end


    desc "Give #{g5k_user} permission to deploy hadoop"
    task :permissions, :roles => [:hadoop] do
      set :user, "root"
      run "chown -R #{g5k_user}:users /opt/hadoop*"
    end

  end

  namespace :configure do
    desc 'configure nodes'
    task 'default' do
      topology::default
      core_site::default
      mapred_site::default
      hadoop_env
    end

    namespace :topology do

      desc 'create the topology of the cluster'
      task :default do
        generate
        transfer
      end

      task :generate do
        File.open("#{hadoop_path}/tmp/master", "w") {|f| f.write first_master }

        slaves = role_hadoop_slaves
        puts slaves.inspect
        File.open("#{hadoop_path}/tmp/slaves", "w") {|f| f.write slaves.join("\n")}
      end

      task :transfer, :roles => [:hadoop_master] do
        set :user, "#{g5k_user}"
        upload "#{hadoop_path}/tmp/master", "#{tarball_destination}/hadoop-1.2.1/conf/master", :via => :scp
        upload "#{hadoop_path}/tmp/slaves", "#{tarball_destination}/hadoop-1.2.1/conf/slaves", :via => :scp
      end

    end

    namespace :core_site do

      desc 'configure core-site.xml'
      task :default do
        generate
        transfer
      end

      task :generate, :roles => [:hadoop] do
        #template = File.read("#{hadoop_path}/templates/core-site.xml.erb")
        template = File.read("#{file_core_site}")
        renderer = ERB.new(template)
        @namenode = "#{first_master}"
        generate = renderer.result(binding)
        core_site = File.open("#{hadoop_path}/tmp/core-site.xml", "w")
        core_site.write(generate)
        core_site.close
      end
      
      task :transfer, :roles => [:hadoop] do
        set :user, "#{g5k_user}"
        upload "#{hadoop_path}/tmp/core-site.xml", "#{tarball_destination}/hadoop-1.2.1/conf/core-site.xml", :via => :scp
      end
    end


    namespace :mapred_site do

      desc 'configure mapred-site.xml'
      task :default do
        generate
        transfer
      end

      task :generate do
        template = File.read("#{file_mapred_site}")
        #template = File.read("#{hadoop_path}/templates/mapred-site.xml.erb")
        renderer = ERB.new(template)
        @jobtracker = "#{first_master}"
        generate = renderer.result(binding)
        core_site = File.open("#{hadoop_path}/tmp/mapred-site.xml", "w")
        core_site.write(generate)
        core_site.close
      end
      
      task :transfer, :roles => [:hadoop] do
        set :user, "#{g5k_user}"
        upload "#{hadoop_path}/tmp/mapred-site.xml", "#{tarball_destination}/hadoop-1.2.1/conf/mapred-site.xml", :via => :scp
      end

    end

    task :hadoop_env, :roles => [:hadoop] do
      set :user, "#{g5k_user}"
      run "perl -pi -e 's,.*JAVA_HOME.*,export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre,g' #{tarball_destination}/hadoop-1.2.1/conf/hadoop-env.sh"
    end
  end

  namespace :cluster do
    
    desc 'Format the cluster'
    task :format_hdfs, :roles => [:hadoop_master] do
      set :user, "#{g5k_user}"
      run "#{tarball_destination}/hadoop-1.2.1/bin/hadoop namenode -format -force"
    end

    desc 'Start the cluster'
    task :start, :roles => [:hadoop_master] do
      set :user, "#{g5k_user}"
      run "#{tarball_destination}/hadoop-1.2.1/bin/start-all.sh"
    end

    desc 'Stop the cluster'
    task :stop, :roles => [:hadoop_master] do
      set :user, "#{g5k_user}"
      run "#{tarball_destination}/hadoop-1.2.1/bin/stop-all.sh"
    end

    desc 'Status of the cluster'
    task :status, :roles => [:hadoop] do
      set :user, "#{g5k_user}"
      run "jps"
    end
  end

  task :benchmark, :roles => [:hadoop_master] do
    set :user, "#{g5k_user}"
    set :hadoop_bench, ENV["BENCH"] 
    run "#{tarball_destination}/hadoop-1.2.1/bin/hadoop jar #{tarball_destination}/hadoop-1.2.1/hadoop-examples*.jar #{hadoop_bench}"
  end

end
