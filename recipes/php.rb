apt_package 'python-software-properties' do
  action :upgrade
end

#TODO: Removing php 7.0 for now since some of our composer packages dont support it. http://jira.klinche.com/browse/KI-1062
# script 'Add PHP 7.0 Repository' do
#   interpreter 'bash'
#   user 'root'
#   code <<-EOH
#     add-apt-repository ppa:ondrej/php-7.0 -y
#     apt-get update
#   EOH
# end
#
# apt_package 'php5' do
#   action :purge
# end
#
# script 'Remove PHP 5 directories' do
#   interpreter 'bash'
#   user 'root'
#   code <<-EOH
#     rm -rf php5/ || true
#   EOH
# end

script 'Add PHP 5.6 Repository' do
  interpreter 'bash'
  user 'root'
  code <<-EOH
    add-apt-repository ppa:ondrej/php5-5.6 -y
    apt-get update
  EOH
end

script 'Update Apache' do
  interpreter 'bash'
  user 'root'
  code <<-EOH
    apt-get install -y apache2
  EOH
end

# %w{php7.0 php7.0-intl php7.0-mcrypt php7.0-curl php7.0-gd  php7.0-mysql php-apcu php-apcu-bc php7.0-sqlite3 php-redis php-ssh2}.each do |pkg|
%w{php5 php5-intl php5-mcrypt php5-curl php5-gd php5-mysql php-apc php5-sqlite php5-redis php5-xsl libssh2-php php5-memcache php-pear php5-dev}.each do |pkg|
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

script "Enable MCrypt" do
  interpreter 'bash'
  user 'root'
  code <<-EOH
      php5enmod mcrypt
  EOH
end

# php5-xsl php-apc  php5-memcache
