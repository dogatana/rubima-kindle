DOWNLOAD_DIR = 'download'
KINDLE_DIR   = 'kindle'

magnify_factor = 1.0
if ENV['MAG']
  f = ENV['MAG'].to_f
  magnify_factor = f if f > 1.0
end

task :default => %i(download setupfile mobi)

desc 'download file'
task :download do
  mkpath DOWNLOAD_DIR
  chdir DOWNLOAD_DIR do
    # download ファイル名の旧→新変換
    unless Dir['p=*'].empty?
      puts 'update names of downloaded files'
      sh 'ruby ../update_name.rb'
    end
    sh 'ruby -I.. ../download.rb'
  end
end

desc'setup files from downloaded files'
task :setupfile do
  mkpath KINDLE_DIR
  chdir DOWNLOAD_DIR do
    sh "ruby -I.. ../setupfile.rb #{KINDLE_DIR}"
  end
end

desc 'make mobi'
task :mobi do
  chdir KINDLE_DIR do
    sh 'ruby -I.. ../make_kindle.rb'
    sh "ruby -I.. ../magnify_image.rb #{magnify_factor}" if magnify_factor > 1.0
    sh 'kindlegen rubima.opf -verbose'
  end
end
