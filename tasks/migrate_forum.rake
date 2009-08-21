namespace :topical do
  desc "Sync migration files into existing app"
  task :sync do
    system "rsync -ruv vendor/plugins/topical/db/migrate db"
  end
end