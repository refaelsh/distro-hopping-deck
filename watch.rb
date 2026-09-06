#!/usr/bin/env ruby
# frozen_string_literal: true

# Serve the deck and reload the browser when slides.adoc or css/ change.
# Open http://127.0.0.1:4173 — live reload does not work on file://.

require "webrick"

ROOT = File.expand_path(__dir__)
Dir.chdir(ROOT)
PORT = Integer(ENV.fetch("PORT", "4173"))
MIME = {
  ".html" => "text/html; charset=utf-8",
  ".css" => "text/css; charset=utf-8",
  ".js" => "application/javascript",
  ".svg" => "image/svg+xml",
  ".png" => "image/png",
  ".jpg" => "image/jpeg",
  ".jpeg" => "image/jpeg",
  ".ico" => "image/x-icon",
}.freeze

WATCH = [
  File.join(ROOT, "slides.adoc"),
  File.join(ROOT, "build.rb"),
  File.join(ROOT, "css/theme.css"),
].freeze

RELOAD_SCRIPT = <<~HTML
  <script>
  (function () {
    var prev = null;
    setInterval(function () {
      fetch("/__stamp", { cache: "no-store" })
        .then(function (r) { return r.text(); })
        .then(function (stamp) {
          if (prev !== null && stamp !== prev) location.reload();
          prev = stamp;
        })
        .catch(function () {});
    }, 300);
  })();
  </script>
HTML

$stdout.sync = true

stamp = "0"
stamp_lock = Mutex.new
build_lock = Mutex.new

mtimes = lambda do
  WATCH.each_with_object({}) do |path, acc|
    acc[path] = File.mtime(path).to_f if File.exist?(path)
  end
end

set_stamp = lambda do
  stamp_lock.synchronize { stamp = Time.now.to_f.to_s }
end

rebuild = lambda do
  build_lock.synchronize do
    puts "Rebuilding…"
    ok = system("bundle", "exec", "ruby", "build.rb")
    warn "build failed" unless ok
    set_stamp.call
  end
end

rebuild.call

prev_mtimes = mtimes.call
Thread.new do
  loop do
    sleep 0.25
    now = mtimes.call
    next if now == prev_mtimes

    adoc_changed = now[WATCH[0]] != prev_mtimes[WATCH[0]] ||
                   now[WATCH[1]] != prev_mtimes[WATCH[1]]
    prev_mtimes = now
    if adoc_changed
      rebuild.call
    else
      puts "CSS changed — reload"
      set_stamp.call
    end
  end
end.abort_on_exception = true

server = WEBrick::HTTPServer.new(
  Port: PORT,
  BindAddress: "127.0.0.1",
  Logger: WEBrick::Log.new($stderr, WEBrick::Log::WARN),
  AccessLog: [],
)

serve = lambda do |req, res|
  if req.path == "/__stamp"
    res["Content-Type"] = "text/plain; charset=utf-8"
    res["Cache-Control"] = "no-store"
    res.body = stamp_lock.synchronize { stamp }
    next
  end

  rel = req.path == "/" ? "index.html" : req.path.sub(%r{\A/}, "")
  rel = rel.split("?", 2).first
  full = File.expand_path(rel, ROOT)
  unless full.start_with?(ROOT + File::SEPARATOR) || full == ROOT
    res.status = 403
    res.body = "forbidden"
    next
  end
  unless File.file?(full)
    res.status = 404
    res.body = "not found"
    next
  end

  ext = File.extname(full).downcase
  body = File.binread(full)
  if ext == ".html"
    html = body.force_encoding("UTF-8")
    html = html.sub("</body>", "#{RELOAD_SCRIPT}</body>") unless html.include?("fetch(\"/__stamp\"")
    body = html
  end
  res["Content-Type"] = MIME.fetch(ext, "application/octet-stream")
  res["Cache-Control"] = "no-store" if ext == ".html" || ext == ".css"
  res.body = body
end

server.mount_proc("/__stamp", &serve)
server.mount_proc("/", &serve)

shutdown = lambda { server.shutdown }
trap("INT", &shutdown)
trap("TERM", &shutdown)

puts "Live reload: http://127.0.0.1:#{PORT}"
puts "Use that URL (not the file). Saving slides.adoc or css/theme.css reloads."
server.start
