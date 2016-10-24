DOWNLOAD_DIR = 'download2'
KINDLE_DIR   = 'kindle'

task :default => %i(download setupfile mobi)

desc 'download file'
task :download do
  mkpath DOWNLOAD_DIR
  chdir DOWNLOAD_DIR do
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
    sh 'kindlegen rubima.opf -verbose'
  end
end
