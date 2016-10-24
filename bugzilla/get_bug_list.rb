#! /usr/bin/env ruby

require "net/http"
require "uri"
# noecho
require "io/console"

def get_url(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == "https"

  req = Net::HTTP::Get.new(uri.request_uri)
  req.basic_auth(uri.user, uri.password)

  http.request(req)
end

def ask(msg, noecho = false)
  print msg
  $stdout.flush

  input = if noecho
    ret = $stdin.noecho(&:gets)
    # print the suppressed newline
    puts
    ret
  else
    gets
  end

  input.chomp
end

def ask_user
  ask("Enter your Bugzilla login name: ")
end

def ask_password
  ask("Enter your Bugzilla password: ", true)
end

def read_credentials
end

url = "https://apibugzilla.suse.com/buglist.cgi?bug_status=UNCONFIRMED&bug_status=NEW&bug_status=CONFIRMED&bug_status=IN_PROGRESS&bug_status=REOPENED&columnlist=priority%2Cproduct%2Ccomponent%2Cassigned_to%2Cbug_status%2Cshort_desc%2Cchangeddate&email1=%28%28yast2-maintainers%7Cyast-internal%7Cautoyast-maintainers%29%40suse.de%7C%28jreidinger%7Caschnell%7Cjsrain%7Clocilka%7Cancor%7Cigonzalezsosa%7Ckanderssen%7Csnwint%7Cschubi%7Cshundhammer%7Clslezak%7Cmvidner%7Cmfilka%7Ccwh%29%40suse.com%29&email2=cwh%40suse.com&email3=jreidinger%40suse.com&emailassigned_to1=1&emailtype1=regexp&emailtype2=substring&emailtype3=substring&limit=0&list_id=5179539&query_format=advanced&resolution=---&ctype=csv&human=1"

uri = URI(url)

uri.user = ask_user
uri.password = ask_password

resp = get_url(uri)

case resp
  when Net::HTTPOK
    fn = Time.now().strftime("%F-%H-%M-%S.csv")
    File.write(fn, resp.body)
  when Net::HTTPUnauthorized
    $stderr.puts "Invalid Bugzilla credentials"
  else
    raise "Bugzilla query failed"
end
