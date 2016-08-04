template '/etc/apache2/conf-available/geoip_custom.conf' do
  source 'geoip_custom.conf.erb'
  mode 0666
  group 'root'
  owner 'root'
end

script 'Enable GeoIP' do
  interpreter 'bash'
  user 'root'
  code <<-EOH
    a2enconf geoip_custom
  EOH
end

search('aws_opsworks_app', 'deploy:true').each do |app|
  Chef::Log.info("********** Starting To Deploy App: '#{app[:name]}' **********")
  
  hostfile_ip = node[:deploy]["#{app[:shortname]}"].key?(:hostfile_entry) ?  node[:deploy]["#{app[:shortname]}"][:hostfile_entry] : '127.0.2.1'  
  hostfile_name = node[:deploy]["#{app[:shortname]}"].key?(:hostfile_name) ?  node[:deploy]["#{app[:shortname]}"][:hostfile_name] : 'localhost1'  

  hostsfile_entry hostfile_ip do
    hostname  hostfile_name
    aliases   app['domains']
    unique    true
    action    :create
  end

  is_vagrant = false
  deploy_to = "/srv/www/#{app[:shortname]}"

  symbolic_release_path = "/srv/www/#{app[:shortname]}/current"

  release_user = node[:deploy]["#{app[:shortname]}"][:release_user]
  release_group = node[:deploy]["#{app[:shortname]}"][:release_group]

  if app[:shortname] == 'vagrant'
    is_vagrant = true
    deploy_to = "/vagrant"
    symbolic_release_path = "/vagrant"
  end

  home = "/home/#{release_user}"

  group release_group

  user release_user do
    action :create
    comment "deploy user"
    gid release_group
    home home
    supports :manage_home => true
    shell '/bin/bash'
    not_if do
      existing_usernames = []
      Etc.passwd {|user| existing_usernames << user['name']}
      existing_usernames.include?(release_user)
    end
  end

  #NOTE: We do not have any of the other types coded here...

  Chef::Log.info("********** Working on Apache For App: '#{app[:name]}' **********")

  apache_site 'default' do
    enable false
  end

  apache_module "http2" do
    enable false
  end

  template_name = 'web_app.conf.erb'

  if app['enable_ssl']
    template_name = 'web_app_ssl.conf.erb'

    file "/etc/apache2/ssl/#{app['domains'].first}.crt" do
      content app['ssl_configuration']['certificate']
      owner 'root'
      group 'root'
      mode '0644'
    end

    file "/etc/apache2/ssl/#{app['domains'].first}.key" do
      content app['ssl_configuration']['private_key']
      owner 'root'
      group 'root'
      mode '0644'
    end

    file "/etc/apache2/ssl/#{app['domains'].first}_ca.crt" do
      content app['ssl_configuration']['chain']
      owner 'root'
      group 'root'
      mode '0644'
    end

  end

  web_app "#{app[:shortname]}" do
    template template_name
    server_aliases app['domains']
    docroot "#{symbolic_release_path}/web"
    application_name app[:shortname]
    server_name app['domains'].first
  end

  rsyslog_file_input 'apache-access' do
    name 'apache-access'
    severity 'info'
    facility 'local0'
    file "/var/log/apache2/#{app[:shortname]}-access.log"
  end

  rsyslog_file_input 'apache-error' do
    name 'apache-error'
    severity 'error'
    facility 'local0'
    file "/var/log/apache2/#{app[:shortname]}-error.log"
  end

  service "rsyslog" do
    action :restart
  end

  if is_vagrant == false

    Chef::Log.info("********** Getting The App From SCM: '#{app[:name]}' **********")

    directory "#{deploy_to}" do
      group release_group
      owner release_user
      mode "0775"
      action :create
      recursive true
    end

    app_source = app[:app_source]

    prepare_git_checkouts(
        :user => release_user,
        :group => release_group,
        :home => home,
        :ssh_key => app_source[:ssh_key]
    ) if app_source[:type].to_s == 'git'

    deploy deploy_to do
      provider Chef::Provider::Deploy::Timestamped
      keep_releases 2
      repository app_source[:url]
      user release_user
      group release_group
      revision app_source[:revision]
      migrate false
      environment({"HOME" => home, "APP_NAME" => app[:shortname]})
      purge_before_symlink(['log', 'tmp/pids', 'public/system'])
      create_dirs_before_symlink(['tmp', 'public', 'config'])
      symlink_before_migrate({})
      symlinks({"system" => "public/system", "pids" => "tmp/pids", "log" => "log"})
      action :deploy

      case app_source[:type].to_s
        when 'git'
          scm_provider Chef::Provider::Git
          enable_submodules true
          depth 1
        when 'svn'
          scm_provider Chef::Provider::Subversion
          svn_username app_source[:user]
          svn_password app_source[:password]
          svn_arguments "--no-auth-cache --non-interactive --trust-server-cert"
          svn_info_args "--no-auth-cache --non-interactive --trust-server-cert"
        else
          raise "unsupported SCM type #{app_source[:type].inspect}"
      end
    end
  else
    Chef::Log.info("********** Running Symlink Recipes '#{app[:name]}' **********")
    include_recipe "deploy::before_symlink"
    include_recipe "deploy::after_restart"
  end

end
