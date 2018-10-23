#!/usr/bin/env ruby

result = `curl -s 'https://api.github.com/orgs/libyui/repos' | grep "\\"name\\":" | sed -e "s/^.*name\\": \\"\\(.*\\)\\",.*$/\\1/"`
repos = result.split "\n"

puts "Found #{repos.size} LibYui repositories"

repos.each do |repo|
  dir = repo.gsub(/^libyui-/, "")

  if File.exist? dir
    puts "Updating #{repo}..."

    Dir.chdir dir do
      `git checkout -q master`
      `git pull --rebase`
    end
  else
    puts "Cloning #{repo}..."
    `git clone git@github.com:libyui/#{repo}.git #{dir}`
  end

  puts
end
