#!/usr/bin/env ruby
# frozen_string_literal: true

# Compile slides.adoc with the Ruby asciidoctor-revealjs converter,
# then drop the generated title <section> so the designed opener is first.

require "open3"

out, err, status = Open3.capture3(
  "bundle", "exec", "asciidoctor-revealjs",
  "-o", "index.html",
  "slides.adoc",
)
$stderr.print err
print out
abort "asciidoctor-revealjs failed" unless status.success?

html = File.read("index.html")
stripped = html.sub(%r{<section[^>]*class="title"[^>]*>.*?</section>\s*}m, "")
File.write("index.html", stripped)
puts "Wrote index.html"
