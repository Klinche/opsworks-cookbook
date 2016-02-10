include_recipe 'chef-sugar'

elasticsearch_user 'elasticsearch' do
  instance_name 'elasticsearch'
end
elasticsearch_install 'elasticsearch' do
  type node['elasticsearch']['install_type'].to_sym # since TK can't symbol.
  instance_name 'elasticsearch'
end

elasticsearch_configure 'elasticsearch' do
  # if you override one of these, you probably want to override all
  allocated_memory node['elasticsearch']['allocated_memory']

  configuration ({
      'cluster.name' => node['elasticsearch']['cluster']['name'],
      'gateway.expected_nodes' => node['elasticsearch']['gateway']['expected_nodes'],
      'discovery.type' => node['elasticsearch']['discovery']['type'],
      'discovery.zen.minimum_master_nodes' => node['elasticsearch']['discovery']['zen']['minimum_master_nodes'],
      'discovery.zen.ping.multicast.enabled' => node['elasticsearch']['discovery']['zen']['ping']['multicast']['enabled'],
      'cloud.aws.region' => node['elasticsearch']['cloud']['aws']['region'],
      'cloud.aws.access_key' => node['elasticsearch']['cloud']['aws']['access_key'],
      'cloud.aws.secret_key' => node['elasticsearch']['cloud']['aws']['secret_key'],
      'discovery.ec2.groups' => node['elasticsearch']['discovery']['ec2']['groups'],
  })

  instance_name 'elasticsearch'
  action :manage
end

elasticsearch_service 'elasticsearch' do
  instance_name 'elasticsearch'
end

elasticsearch_plugin 'elasticsearch-cloud-aws' do
  url 'elasticsearch/elasticsearch-cloud-aws/2.7.1'
  instance_name 'elasticsearch'
  action :install
end