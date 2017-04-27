require 'chef'
require 'json'

def output_list(list)
  list.each do |name, versions|
    #puts "#{name}: #{versions}"
  end
end

def get_cookbook_list(endpoint)
  cb_list = {}
  cookbooks = endpoint.get_rest('/cookbooks?num_versions=all')
  cookbooks.each do |name, data|
    data['versions'].each do |version_hash|
      version = version_hash['version']
      if cb_list[name] && !cb_list[name].include?(version)
        cb_list[name].push(version)
      else
        cb_list[name] = [version]
      end
    end
  end
  cb_list
end

def get_cookbook_count(cb_list)
  cb_count_list = {}
  cb_list.each do |name, versions|
    cb_count_list[name] = versions.count
  end
  cb_count_list
end

def get_unused_cookbooks(used_list, cb_list)
  unused_list = {}
  cb_list.each do |name, versions|
    if used_list[name].nil? # Not in the used list at all (Remove all versions)
      unused_list[name] = versions
    elsif used_list[name].sort != versions  # Is in the used cookbook list, but version arrays do not match (Find unused versions)
      unused_list[name] = versions - used_list[name]
    end
  end
  unused_list
end

orgs = ARGV[0].split(',') || ['myorg']
knife_config = ARGV[1] || "#{ENV['HOME']}/.chef/knife.rb"
puts knife_config
Chef::Config.from_file(knife_config)

chef_server_root = Chef::Config['chef_server_url'][/.*\//]
stale_orgs = []
orgs.each do |org|
  chef_endpoint = Chef::ServerAPI.new("#{chef_server_root}#{org}")
  puts "Cookbook report for organization #{org}:"
  cb_list = get_cookbook_list(chef_endpoint)
  version_count = get_cookbook_count(cb_list).sort_by(&:last).reverse.to_h
  output_list(version_count)
  nodes = Chef::Search::Query.new("#{chef_server_root}#{org}").search(:node, '*:*', :filter_result => {'name' => ['name'], 'cookbooks' => ['cookbooks'], 'ohai_time' => ['ohai_time']} )
  used_cookbooks = {}
  #nodes[0].select{|node| node.class == Array}.each do |node|
  nodes[0].select{|node| !node['cookbooks'].nil?}.each do |node|
    node['cookbooks'].each do |name, version_hash|
      version = version_hash['version']
      if used_cookbooks[name] && !used_cookbooks[name].include?(version)
        used_cookbooks[name].push(version)
      else
        used_cookbooks[name] = [version]
      end
    end
  end
  threshold_in_days = 30
  stale_nodes = []
  nodes[0].each do |n|
    if (Time.now.to_i - n['ohai_time'].to_i) >= threshold_in_days * 86400
      stale_nodes.push(n['name'])
    end
  end
  stale_nodes_hash = {'threshold_days': threshold_in_days, 'count': stale_nodes.count, 'list': stale_nodes}
  stale_orgs.push(org) if stale_nodes.count == nodes[0].count
  # puts "Unused cookbooks: #{get_unused_cookbooks(used_cookbooks, cb_list)}"
  # puts "Stale orgs: #{stale_orgs}"
  File.write("output/#{org}_unused_cookbooks.json", JSON.pretty_generate(get_unused_cookbooks(used_cookbooks, cb_list)))
  File.write("output/#{org}_cookbook_count.json", JSON.pretty_generate(version_count))
  File.write("output/#{org}_#{threshold_in_days}d_stale_nodes.json", JSON.pretty_generate(stale_nodes_hash))
end