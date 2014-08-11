#!/usr/bin/env ruby

# via https://github.com/akirahrkw/levenshtein-distance
# http://en.wikipedia.org/wiki/Levenshtein_distance
class String

  def ld(b)
    levenshtein_distance(b)
  end

  def levenshtein_distance(b)
    a = self
    a_len = a.length
    b_len = b.length
    d = Array.new(a_len + 1).map! {
      Array.new(b_len + 1).map!{
        0
      }
    }
    (a_len + 1).times { |i| d[i][0] = i }
    (b_len + 1).times { |i| d[0][i] = i }

    for i in 1..(a_len)
      for j in 1..(b_len)
        cost = (a[i - 1] == b[j - 1]) ? 0 : 1
        d[i][j] = [ d[i-1][j] + 1 , d[i][j-1] + 1 ,d[i-1][j-1] + cost].min
      end
    end
    d[-1][-1]
  end
end

def find_script(script)
  # try to locate script
  return script if File.exists? script

  # try relative path
  root = Dir.pwd
  s = File.expand_path(File.join(root, script))
  return s if File.exists? s

  # try searching
  files = Dir.glob(File.join(root, "**/**")).reject{ |f|
    # select only actual script files to look at
    File.directory? f or
      f =~ /\.(json|test.*)|\/digest$/ or
      File.dirname(f) == root or
      File.dirname(f) =~ %r{/(test|lib)/?}
  }
  script = files.find_all{ |f| f.include? script }.sort { |a,b|
    script.ld(File.basename(a)) <=> script.ld(File.basename(b))
  }.shift

  return script
end
