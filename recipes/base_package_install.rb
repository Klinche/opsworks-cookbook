script 'update' do
  interpreter 'bash'
  user 'root'
  code <<-EOH
  sudo apt-get update
  EOH
end

%w{geoip-bin geoip-database libgeoip-dev libgeoip1 libapache2-mod-geoip pdftk graphviz acl}.each do |pkg|
  script "Reconfigure all outstanding packages in case package before #{pkg} fails us" do
    interpreter 'bash'
    user 'root'
    code <<-EOH
        sudo dpkg --configure -a
    EOH
  end

  package pkg do
    timeout 4000
    action :upgrade
  end

  script "Reconfigure all outstanding packages in case #{pkg} fails us" do
    interpreter 'bash'
    user 'root'
    code <<-EOH
      sudo dpkg --configure -a
    EOH
  end
end

script 'Install Bundler' do
  interpreter 'bash'
  user 'root'
  code <<-EOH
    gem install bundler
  EOH
end


script 'Update CA Certificates' do
  interpreter 'bash'
  user 'root'
  code <<-EOH
    update-ca-certificates
  EOH
end
