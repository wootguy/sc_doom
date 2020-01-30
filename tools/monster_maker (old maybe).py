import glob, os
import subprocess
import shutil
import collections
import struct

magick_path = "magick"
spriteguy_path = "spriteguy"

image_names = []
sizes = {}
offsets = {}
scale = 2
temp_files = []
light_levels = ['_L3', '_L2', '_L1', '_L0']
#light_levels = ['_LB']

for file in glob.glob("*.spr"):
	os.remove(file)

for file in glob.glob("*.png"):
	image_names.append( os.path.splitext(os.path.basename(file))[0] )

for name in image_names:
	lump = name + ".lmp"
	if os.path.exists(lump):
		f = open(lump, "rb")
		s = f.read(8)
		w, h, x, y = struct.unpack("<hhhh", s)
		offsets[name] = [-x*scale, y*scale]
		sizes[name] = [w*scale, h*scale]
		
		offsets[name] = [-int((w*scale)/2 + 2.5), h*scale]
	
# Flip images since goldsource can't do sprite mirroring
for name in list(image_names):
	angle = name[4:]
	if len(angle) > 2:
		newAngle = angle[2:4] + angle[0:2]
		newName = name[:4] + newAngle
		print("Flipping %s -> %s" % (name, newName))
		
		args = [magick_path, 'convert', '-flop', name + ".png", newName + ".png"]
		subprocess.check_call(args)
		offsets[newName] = offsets[name]
		sizes[newName] = sizes[name]
		image_names.append(newName)
		temp_files.append(newName + ".png")
	
		
for name in image_names:
	print("Adding borders %s" % name)
	
	# scale up
	'''
	args = [magick_path, 'convert', '-background', 'transparent', '-interpolate', 'Nearest', '-filter', 'point', '-resize', '200%', name + ".png", name + "_L3.png"]
	subprocess.check_call(args)
	'''
	
	# Add 1px border so HL's bilinear filtering doesn't get to wrap pixels at the edges
	args = [magick_path, 'convert', '-background', 'transparent', '-bordercolor', 'transparent', '-border', '2x2', name + ".png", name + "_L3.png"]
	subprocess.check_call(args)
	
	'''
	width = sizes[name][0]+4
	args = [magick_path, 'convert', '-background', 'transparent', '-flip', '-gravity', 'north', '-extent', '%sx170' % width, name + "_L3.png", name + "_L3.png"]
	subprocess.check_call(args)
	'''
	temp_files.append(name + "_L3.png")

	
for name in image_names:
	print("Baking light levels %s" % name)
	'''
	args = [magick_path, 'convert', '-background', 'transparent', '-fill', 'black', '-colorize', '90%', name + "_L3.png", name + "_L0.png"]
	temp_files.append(name + "_L0.png")
	offsets[name + "_L0.png"] = offsets[name]
	subprocess.check_call(args)
	
	args = [magick_path, 'convert', '-background', 'transparent', '-fill', 'black', '-colorize', '60%', name + "_L3.png", name + "_L1.png"]
	temp_files.append(name + "_L1.png")
	offsets[name + "_L1.png"] = offsets[name]
	subprocess.check_call(args)
	
	args = [magick_path, 'convert', '-background', 'transparent', '-fill', 'black', '-colorize', '30%', name + "_L3.png", name + "_L2.png"]
	temp_files.append(name + "_L2.png")
	offsets[name + "_L2.png"] = offsets[name]
	subprocess.check_call(args)
	'''
	'''
	# scale up
	args = [magick_path, 'convert', '-background', 'transparent', '-interpolate', 'Nearest', '-filter', 'point', '-resize', '200%', name + ".png", name + "_LB.png"]
	subprocess.check_call(args)
	
	# Add 1px border so HL's bilinear filtering doesn't get to wrap pixels at the edges
	args = [magick_path, 'convert', '-background', 'transparent', '-bordercolor', 'transparent', '-border', '2x2', name + "_LB.png", name + "_LB.png"]
	subprocess.check_call(args)
	
	args = [magick_path, 'convert', '-fill', 'black', '-colorize', '99%', name + "_LB.png", name + "_LB.png"]
	temp_files.append(name + "_LB.png")
	offsets[name + "_LB.png"] = offsets[name]
	subprocess.check_call(args)
	
	# remove alpha
	args = [magick_path, 'convert', '-alpha', 'remove', '-background', 'blue', name + "_LB.png", name + "_LB.png"]
	subprocess.check_call(args)
	'''
	
	
count = 0
panims = collections.OrderedDict({})
for name in image_names:
	count += 1
	angle = name[-1:]
	if angle == '0':
		basename = name[:-2]
		if basename not in panims:
			panims[basename] = []
		panims[basename].append(name)
	else:
		for level in light_levels:
			print("Making upright sprites %s" % (name + level))
			ofs = offsets[name]
			args = [spriteguy_path, name + level + ".png[%s,%s]" % (ofs[0], ofs[1]), name + level + ".spr", "type=upright"]
			subprocess.check_call(args)
			
regulars = []
for anim in panims:
	print("Making parallel sprites %s" % anim)
	for level in light_levels:
		args = [spriteguy_path]
		for name in panims[anim]:
			ofs = offsets[name]
			args.append(name + level + ".png[%s,%s]" % (ofs[0], ofs[1]))
			if level == '_L3' or level == '_LB':
				regulars.append(name)
		args.append(anim + level + ".spr")
		args.append("type=upright")
		subprocess.check_call(args)
		
	
# Make an animation array def for angelscript
anims = collections.OrderedDict({})
for name in image_names:
	base = name[:4]
	angle = name[-1:]
	if angle == '0':
		continue
	if base not in anims:
		anims[base] = collections.OrderedDict({})
	frame = name[4]
	if not frame in anims[base]:
		anims[base][frame] = []
	anims[base][frame].append(name)

	
def base36(num):
	b36 = ''
	charset = "0123456789abcdefghijklmnopqrstuvwxyz"
	
	while num != 0:
		c = charset[num % 36]
		b36 = c + b36
		num /= 36
		num = int(num)
	return b36	
	
fh = open("anims.as", "w")

sprite_path = "d/"
superImages = []

idx = 36
for base in anims:
	sprite_prefix = base.lower()[0]
	sprite_prefix = 'd'
	fh.write("array< array< array<string> > > SPR_ANIM_%s = {\n" % base)
	for lvl, level in enumerate(light_levels):
		fh.write("\t{\n")
		for i, key in enumerate(anims[base]):
			fh.write('\t\t{ ')
			
			for k, frame in enumerate(sorted(anims[base][key])):
				comma = ", " if k < len(anims[base][key])-1 else " "
				nice_name = frame + level
				ofs = offsets[frame]
				if lvl == 3 or len(light_levels) == 1:
					superImages.append(frame + "_L3.png[%s,%s]" % (ofs[0]*scale, ofs[1]*scale))	
				real_name = sprite_prefix + base36(idx)
				fh.write('"%s.spr"%s' % (sprite_path + real_name, comma))
				#os.rename(frame + level + ".spr", sprite_prefix + base36(idx) + ".spr")
				idx += 1
			
			comma = "," if i < len(anims[base])-1 else ""
			fh.write('}%s\n' % comma)
		comma = "," if lvl < len(light_levels)-1 else ""
		fh.write('\t}%s\n' % comma)
	fh.write("};\n")
	
	# Now make the array for death framesa
	fh.write("array<string> SPR_ANIM_DEATH_%s = { " % base)
	idx = 0
	for k, reg in enumerate(regulars):
		nice_name = frame + level
		ofs = offsets[frame]
		superImages.append(reg + "_L3.png[%s,%s]" % (ofs[0]*scale, ofs[1]*scale))	
		#os.rename(reg + ".spr", sprite_prefix + base36(idx) + ".spr")
		comma = ", " if k < len(regulars)-1 else " "
		fh.write('"%s.spr"%s' % (sprite_path + sprite_prefix + base36(idx), comma))
		idx += 1
	fh.write("};\n")
	
fh.close()

superName = "TROO"	
print("Making super sprite %s" % superName)
args = [spriteguy_path] + superImages + [superName + ".spr", "type=upright"]
subprocess.check_call(args)


# cleanup
for file in temp_files:
	os.remove(file)