apt_package 'python-software-properties' do
  action :upgrade
end

#TODO: Removing php 7.0 for now since some of our composer packages dont support it. http://jira.klinche.com/browse/KI-1062
script 'Add PHP 5.6-7.0 Repository' do
  interpreter 'bash'
  user 'root'
  code <<-EOH
    add-apt-repository ppa:chris-lea/libsodium -y
    add-apt-repository ppa:ondrej/php -y
    apt-add-repository ppa:ondrej/apache2 -y
    apt-get update
  EOH
end

apt_package 'php5' do
  action :purge
end

script 'Remove PHP 5 directories' do
  interpreter 'bash'
  user 'root'
  code <<-EOH
    rm -rf php5/ || true
  EOH
end

script 'Update Apache' do
  interpreter 'bash'
  user 'root'
  code <<-EOH
    apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"  install -y apache2
  EOH
end

%w{php5 php5-intl php5-mcrypt php5-curl php5-gd php5-mysql php-apc php5-sqlite php5-redis php5-xsl libssh2-php php5-memcache php-pear php5-dev php5-apcu php5-cli php5-common php5-json php5-readline php5-ssh2 libapache2-mod-php5}.each do |pkg|
  script "Reconfigure all outstanding packages in case package before #{pkg} fails us" do
    interpreter 'bash'
    user 'root'
    code <<-EOH
        sudo dpkg --configure -a
    EOH
  end

  script "Purge packages #{pkg} fails us" do
    interpreter 'bash'
    user 'root'
    code <<-EOH
        sudo apt-get purge -y #{pkg} 2>/dev/null || true
    EOH
  end

  script "Reconfigure all outstanding packages in case #{pkg} fails us" do
    interpreter 'bash'
    user 'root'
    code <<-EOH
      sudo dpkg --configure -a
    EOH
  end
end

%w{php7.0 php7.0-intl php7.0-soap php7.0-dev libsodium-dev php-gmagick php-imagick php-pear php7.0-mcrypt php7.0-curl php7.0-gd php7.0-bcmath php7.0-mbstring php7.0-zip php7.0-mysql php-apcu php-apcu-bc php7.0-sqlite3 php-redis php-ssh2 php7.0-xml libapache2-mod-php7.0}.each do |pkg|
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

script "Reset Blackfire and NewRelic" do
  interpreter 'bash'
  user 'root'
  code <<-EOH
      sudo mv /etc/php5/mods-available/newrelic.ini /etc/php/7.0/mods-available/ 2>/dev/null || true
      sudo mv /etc/php5/mods-available/blackfire.ini /etc/php/7.0/mods-available/ 2>/dev/null || true
      rm -rf /etc/php5
      rm -rf /etc/php/5.6
      rm -rf /usr/lib/php5
      ln -s /usr/lib/blackfire-php/amd64/blackfire-20151012.so /usr/lib/php/20151012/blackfire.so
      ln -s /usr/lib/newrelic-php5/agent/x64/newrelic-20151012.so /usr/lib/php/20151012/newrelic.so
      phpenmod newrelic
      phpenmod blackfire
  EOH
end


script "Enable MCrypt" do
  interpreter 'bash'
  user 'root'
  code <<-EOH
      phpenmod mcrypt
  EOH
end


template '/etc/php/7.0/mods-available/proctitle.ini' do
  source 'extension.ini.erb'
  mode 0666
  group 'root'
  owner 'root'
  variables({
                :extension_line => 'proctitle.so'
            })
end

script "Install Proctitle" do
  interpreter 'bash'
  user 'root'
  code <<-EOH
      pecl channel-update pecl.php.net
      printf "\n" | pecl install proctitle-alpha
      phpenmod proctitle
  EOH
end

template '/etc/php/7.0/mods-available/libsodium.ini' do
  source 'extension.ini.erb'
  mode 0666
  group 'root'
  owner 'root'
  variables({
                :extension_line => 'libsodium.so'
            })
end

script "Install LibSodium" do
  interpreter 'bash'
  user 'root'
  code <<-EOH
      pecl channel-update pecl.php.net
      printf "\n" | pecl install libsodium
      phpenmod libsodium
  EOH
end

template '/etc/php/7.0/mods-available/uopz.ini' do
  source 'extension.ini.erb'
  mode 0666
  group 'root'
  owner 'root'
  variables({
                :extension_line => 'uopz.so'
            })
end

script "Install uopz" do
  interpreter 'bash'
  user 'root'
  code <<-EOH
      pecl channel-update pecl.php.net
      printf "\n" | pecl install uopz
      phpenmod uopz
  EOH
end

service "php7.0-fpm" do
  action :restart
  only_if { File.exist?("/etc/init.d/php7.0-fpm") }
end

service "apache2" do
  action :restart
end

# php5-xsl php-apc  php5-memcache
