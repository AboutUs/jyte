src  = IO.readlines(File.dirname(__FILE__)+'/lib/templates/solr.yml')
dest = File.new(File.dirname(__FILE__)+'/../../../config/solr.yml','w+')
dest << src
dest.close