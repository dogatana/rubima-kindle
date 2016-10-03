require 'rubima'
require 'fileutils'

Dir.glob('magazine.rubyist.net/index.html@*').each do |file|
  next if file =~ /@c=login/  # スキップ
  base = File.basename(file)
  new_base = Rubima.convert_name(base, false)
  #next unless new_base =~ /^\d+/
  new_file = 'kindle/' + new_base

  if new_file =~ /html$/
    html = Rubima.fix_file(file)
    File.open(new_file, 'w:utf-8').write(html)
  else
    FileUtils.cp(file, new_file)
  end
end
FileUtils.cp_r('magazine.rubyist.net/theme', 'kindle')
