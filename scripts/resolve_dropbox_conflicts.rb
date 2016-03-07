require 'fileutils'
include FileUtils

conflicts = `find ~/Dropbox -name "*conflicted*"`.split("\n")
same, diff = conflicts.select { |conflict|
  actual = conflict.sub(/ \(.*'s conflicted copy \d{4}-\d{2}-\d{2}\)/, '')
  diff = `diff "#{actual}" "#{conflict}"`
  diff.empty?
}

same.each do |conflict|
  rm conflict
end

puts diff.map { |conflict|
  [conflict, diff].join("\n")
}.join("\n")
