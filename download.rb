require 'rubima'

rest = Rubima::DL.get_master_index('index.html')
done = { 'index.html' => '' }

until rest.empty?
  puts "#{done.size} / #{rest.size}"
  target, item = rest.shift

  target = 'index.html' if target == './'
  next if target =~ /^(http|ftp|mailto|\.\/\?c=(diff|login|search|prep?\-)|#)/
  target = target.split(/#/)[0] # remove id
  next if done.key?(target)
  
  puts "# process #{target}"
  
  data = Rubima::DL::load_file(target)
  file = Rubima.get_name(target)
  
  # save it
  unless File.exist?(file)
    puts "# save to #{file}"
    open(file, 'wb').write(data) 
    item.file = file
  end
  
  # parse it if it's html
  if data =~ /^<!DOCTYPE/
    puts "# parse #{file}"
    links = Rubima::DL::parse_ref(data)
    puts "# got #{links.size} links"
    rest.merge!(links)
  end
  done[target] = item
end

Rubima::DL.load_additional_file
