require 'benchmark'
require 'cityhash'
require 'digest/md5'
require 'digest/sha1'
require 'murmurhash3'
require 'zlib'

n = 500000

# text = "Four score and seven years ago our fathers brought forth on this continent a new nation, conceived in liberty, and dedicated to the proposition that all men are created equal. Now we are engaged in a great civil war, testing whether that nation, or any nation so conceived and so dedicated, can long endure. We are met on a great battlefield of that war. We have come to dedicate a portion of that field, as a final resting place for those who here gave their lives that that nation might live. It is altogether fitting and proper that we should do this. But, in a larger sense, we can not dedicate, we can not consecrate, we can not hallow this ground. The brave men, living and dead, who struggled here, have consecrated it, far above our poor power to add or detract. The world will little note, nor long remember what we say here, but it can never forget what they did here. It is for us the living, rather, to be dedicated here to the unfinished work which they who fought here have thus far so nobly advanced. It is rather for us to be here dedicated to the great task remaining before us—that from these honored dead we take increased devotion to that cause for which they gave the last full measure of devotion—that we here highly resolve that these dead shall not have died in vain—that this nation, under God, shall have a new birth of freedom—and that government of the people, by the people, for the people, shall not perish from the earth."

text = "s34gull@gmail.com"

Benchmark.bm do |x|
	x.report("crc32") { for i in 1..n; Zlib.crc32("#{text}:#{i}"); end }
	x.report("murmur3_v32") { for i in 1..n; MurmurHash3::V32.str_hash("#{text}:#{i}"); end }
	x.report("murmur3_v128") { for i in 1..n; MurmurHash3::V128.str_hash("#{text}:#{i}"); end }
	x.report("cityhash_v32") { for i in 1..n; CityHash.hash32("#{text}:#{i}"); end }
	x.report("cityhash_v64") { for i in 1..n; CityHash.hash64("#{text}:#{i}"); end }
	x.report("cityhash_v128") { for i in 1..n; CityHash.hash128("#{text}:#{i}"); end }
	x.report("cityhash_v128crc") { for i in 1..n; CityHash.hash128crc("#{text}:#{i}"); end }
 	x.report("md5") { for i in 1..n; Digest::MD5.hexdigest("#{text}:#{i}"); end }
 	x.report("sha1") { for i in 1..n; Digest::SHA1.hexdigest("#{text}:#{i}"); end }
end