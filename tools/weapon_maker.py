import glob, os
import subprocess
import shutil
import collections
import struct
from PIL import Image

magick_path = "magick"
spriteguy_path = "spriteguy"

image_names = []
sizes = {}
offsets = {}
scales = [8, 5, 3.5, 2.5]
temp_files = []
superImages = []
light_levels = ['_L3', '_L2', '_L1', '_L0']
#light_levels = ['_LB']
frames = []

for file in glob.glob("*.spr"):
	os.remove(file)

for file in glob.glob("*.png"):
	image_names.append( os.path.splitext(os.path.basename(file))[0] )

for scale in scales:
	for name in image_names:	
		img = Image.open(name + ".png")
		width, height = img.size
	
		scale_suffix = "_S%s" % scale
		args = [magick_path, 'convert', '-background', 'transparent', '-interpolate', 'Nearest', '-filter', 'point', 
				'-resize', '%s%%' % (scale*100), name + ".png", name + scale_suffix + ".png"]
		subprocess.check_call(args)
		
		newWidth = width*scale
		newHeight = height*scale
		
		tilesX = 1
		tilesY = 1
		if newWidth > 512 or newHeight > 512:
			args = [magick_path, 'convert', '-crop', '512x512', name + scale_suffix + ".png", name + scale_suffix + "_%d.png"]
			subprocess.check_call(args)
			tilesX = int( (newWidth+511) / 512 )
			tilesY = int( (newHeight+511) / 512 )
			numTiles = tilesX * tilesY
			#print("Splitting %s sprite into %s tiles" % (name, numTiles))
			for i in range(numTiles):
				#print("ADD %s" % i)
				temp_files.append(name + scale_suffix + "_%s.png" % i)
				superImages.append(name + scale_suffix + "_%s.png" % i)
		else:
			superImages.append(name + scale_suffix + ".png")
			
		print("%s %s%% (%s, %s)" % (name, scale*100, tilesX, tilesY))
			
		frames.append({"tilesX": tilesX, "tilesY": tilesY, "width": width, "height": height})
		
		temp_files.append(name + scale_suffix + ".png")
		
		args = [magick_path, 'convert', '-alpha', 'remove', '-background', 'purple', name + scale_suffix + ".png", name + scale_suffix + ".png"]
		subprocess.check_call(args)

superName = 'rpg'
print("Making super sprite %s" % superName)
args = [spriteguy_path] + superImages + [superName + ".spr"]
subprocess.check_call(args)

# cleanup
for file in temp_files:
	try:
		os.remove(file)
	except:
		pass
		
fh = open("frames.as", "w")
fh.write("array<FrameInfo> frameInfo = {\n")
for idx, frame in enumerate(frames):
	if idx >= len(image_names):
		break
	fh.write("\tFrameInfo(%s, %s, %s, %s, %s),\n" % (frame["width"], frame["height"], frame["tilesX"], frame["tilesY"], 0))
fh.write("};\n")

fh.write("array<TileInfo> tileInfo = {\n")
for k, frame in enumerate(frames):
	newline = "\n" if k % 6 == 5 or k == len(frames)-1 else " "
	tab = "\t" if k % 6 == 0 else ""
	fh.write("%sTileInfo(%s, %s),%s" % (tab, frame["tilesX"], frame["tilesY"], newline))
fh.write("};\n")
fh.close()