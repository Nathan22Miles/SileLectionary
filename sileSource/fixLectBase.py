import re

with open("lect.base.lua") as fd:
	text = fd.read()

def fixPreload(m):
	part = m.group(2)
	# print "part2: " + part
	part = re.sub(r"lua-libraries\\\\", "", part)
	part = re.sub(r"\\\\", ".", part)
	#print part
	return m.group(1) + part

text = re.sub(r'"(classes|core|languages|packages)/', r'"\1.', text)
text = re.sub(r'(package\.preload\[\s*")([^"]+)', fixPreload, text)
text = re.sub(r'std\.debug_init\.init', 'std.debug_init', text)

with open("lect.lua", "w") as fd:
	fd.write(text)