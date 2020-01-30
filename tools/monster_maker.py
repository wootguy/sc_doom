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
scale = 1
temp_files = []
spr_type = "type=upright"
#spr_type = ''
projectile_mode = False
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
		
		#offsets[name] = [(-w/2) - 1, 0] #smoke puff
		#offsets[name] = [(-w/2), h] # items
	
# Flip images since goldsource can't do sprite mirroring
for name in list(image_names):
	angle = name[4:]
	if len(angle) > 2:
		newAngle = angle[2:4] + angle[0:2]
		newName = name[:4] + newAngle
		print("Flipping %s -> %s" % (name, newName))
		
		args = [magick_path, 'convert', '-flop', name + ".png", newName + ".png"]
		subprocess.check_call(args)
		if name in offsets:
			offsets[newName] = offsets[name]
			sizes[newName] = sizes[name]
		image_names.append(newName)
		temp_files.append(newName + ".png")
	
		
for name in image_names:
	print("Adding borders %s" % name)
	
	# scale up
	args = [magick_path, 'convert', '-background', 'transparent', '-interpolate', 'Nearest', '-filter', 'point', '-resize', '%s%%' % (scale*100), name + ".png", name + "_L3.png"]
	subprocess.check_call(args)
	
	# Add 1px border so HL's bilinear filtering doesn't get to wrap pixels at the edges
	args = [magick_path, 'convert', '-background', 'transparent', '-bordercolor', 'transparent', '-border', '2x2', name + "_L3.png", name + "_L3.png"]
	subprocess.check_call(args)
	
	args = [magick_path, 'convert', '-alpha', 'remove', '-background', 'purple', name + "_L3.png", name + "_L3.png"]
	subprocess.check_call(args)
	
	temp_files.append(name + "_L3.png")
	
	
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
			
regulars = []
for anim in panims:
	for name in panims[anim]:
		regulars.append(name)
		
	
# Make an animation array def for angelscript
anims = collections.OrderedDict({})
for name in image_names:
	base = name[:4]
	angle = name[-1:]
	if angle == '0':
		continue
	if base not in anims:
		anims[base] = collections.OrderedDict({})
		
	if len(name) > 4:
		frame = name[4]
		if not frame in anims[base]:
			anims[base][frame] = []
		anims[base][frame].append(name)
	
superImages = []

for base in anims:
	for i, key in enumerate(anims[base]):
		for k, frame in enumerate(sorted(anims[base][key])):
			if not projectile_mode:
				if frame in offsets:
					ofs = offsets[frame]
					superImages.append(frame + "_L3.png[%s,%s]" % (ofs[0]*scale, ofs[1]*scale))
				else:
					print("ADD FRAME " + frame)
					superImages.append(frame + "_L3.png")
	
# Now make the array for death framesa
for k, reg in enumerate(regulars):
	if reg in offsets:
		ofs = offsets[reg]
		superImages.append(reg + "_L3.png[%s,%s]" % (ofs[0]*scale, ofs[1]*scale))
	else:
		superImages.append(reg + "_L3.png")

if projectile_mode or True:
	superImages = sorted(superImages)

superName = base
print("Making super sprite %s" % superName)
args = [spriteguy_path, '-v'] + superImages + [superName + ".spr"]
if spr_type:
	args.append(spr_type)
subprocess.check_call(args)


# cleanup
for file in temp_files:
	os.remove(file)