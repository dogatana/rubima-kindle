require 'fileutils'

Dir['p=*'].each do |old|
  new = old.sub(/^p=/, 'p_').sub(/f=/, '')
  unless old == new
    #puts "#{old} => #{new}" 
    FileUtils.mv old, new
  end
end
