require 'fileutils'
include FileUtils

conflicts = `find ~/Dropbox -name "*conflicted*"`.split("\n")
diffs = conflicts.each.with_object({}) { |conflict, diffs|
  actual = conflict.sub(/ \(.*'s conflicted copy \d{4}-\d{2}-\d{2}\)/, '')
  diffs[conflict] = `diff "#{actual}" "#{conflict}"`
}

same, diff = diffs.partition {|_,diff| diff.empty? }

same.each do |conflict, _|
  rm conflict
end

puts diff.map { |conflict, diff|
  [conflict, diff].join("\n")
}.join("\n")

# require 'pry'
# binding.pry
