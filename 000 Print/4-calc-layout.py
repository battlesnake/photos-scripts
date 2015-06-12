#!/usr/bin/python

from os import listdir, environ, fork, execv
from os.path import isfile, join
from PIL import Image
from math import ceil, floor
from sys import setrecursionlimit
import copy

# Image tile
class Tile:

	def __init__(self, file, x, y, width, height):
		self.file = file
		self.x = x
		self.y = y
		self.width = width
		self.height = height

# Piecewise horizontal interval
class PHI:

	def __init__(self, width):
		self.head = PHI.HI(width)

	def __str__(self):
		return self.head.__str__()

	def cursor(self):
		return PHI.Cursor(self.head)

	class Cursor:

		def __init__(self, head):
			self.head = head
			self.reset()

		def reset(self):
			self.position = 0
			self.offset = 0
			self.current = self.head
			return self

		# Try to read a contiguous block and return maximum value found on
		# success
		def try_read(self, delta):
			if delta <= 0:
				raise Exception("Bad read")
			item = self.current
			position = self.position
			remaining = delta + self.offset
			max = item.value
			while item.length <= remaining:
				if item.value > max:
					max = item.value
				remaining -= item.length
				position += item.length
				if remaining > 0 or item.next is not None:
					item = item.next
				else:
					remaining = item.length
					break
				if item is None:
					return None
			if item.value > max:
				max = item.value
			self.current = item
			self.position = position
			self.offset = remaining
			return max

		# Moves the cursor by the given amount.
		# Moves to a new row if needed, to ensure that the read block is
		# contiguous.
		def read(self, delta):
			max = self.try_read(delta)
			if max is not None:
				return max
			elif result.x > 0:
				return self.read_newline(delta)
			else:
				raise Exception("Failed to read {0}".format(delta))

		def read_newline(self, delta):
			self.reset()
			result = self.try_read(delta)
			if result is None:
				raise Exception("Failed to read {0} from start of line".format(delta))
			return result

		def write(self, delta_x, delta_y):
			dup = copy.copy(self)
			y = dup.try_read(delta_x)
			if y is None:
				dup.reset()
				y = dup.try_read(delta_x)
				self.reset()
				if y is None:
					raise Exception("Write failed")
			res = [self.position, y]
			self.current.set(self.offset, delta_x, y + delta_y)
			if self.try_read(delta_x) is None:
				raise Exception("Write failed")
			return res

	# Horizontal interval (double linked-list)
	class HI:

		# Inserts new subrange after 'prev'
		def __init__(self, length, value = 0, prev = None):
			self.length = length
			self.value = value
			self.prev = prev
			self.next = None
			if prev is not None:
				self.next = prev.next
				prev.next = self
				if self.next is not None:
					self.next.prev = self

		def __str__(self):
			item = self
			while item.prev:
				item = item.prev
			str = ""
			x = 0
			while item:
				str = str + " -- {0} to {1} ({2}) -- ".format(x, x + item.length - 1, item.value)
				x += item.length
				item = item.next
			return str

		# Removes subrange (this is the only method that removes the context
		# item, no other methods call this on their context instance.
		def remove(self):
			if self.prev is not None:
				self.prev.next = self.next
			if self.next is not None:
				self.next.prev = self.prev

		# Splits subrange into two
		def split(self, offset):
			if offset < 0 or offset >= self.length:
				raise Exception("Split outside subrange")
			if offset == 0:
				return
			llength = offset
			rlength = self.length - offset
			self.length = llength
			return PHI.HI(rlength, self.value, self)

		# Merges subrange into next, taking maximum value, returns Δlength
		def merge_next(self, maxgrowth = -1):
			if self.next is None:
				raise Exception("Cannot merge, subrange is last in range")
			growth = self.next.length
			if maxgrowth >= 0 and growth > maxgrowth:
				return 0
			self.value = max(self.value, self.next.value)
			self.length += self.next.length
			self.next.remove()
			return growth

		# Merges repeatedly until we have reached a certain length
		def merge_for(self, length):
			if length <= 0:
				raise Exception("Null merge")
			if length <= self.length:
				return
			remaining = length - self.length
			while True:
				growth = self.merge_next(remaining)
				remaining -= growth
				if growth == 0:
					break
			if remaining:
				if self.next is None:
					raise Exception("Merge failed, overflowed range")
				self.next.split(remaining)
				growth = self.merge_next(remaining)
				remaining -= growth
			if remaining > 0:
				raise Exception("Logic error")
			return self

		def set(self, offset, width, value):
			if offset < 0:
				prev = self.prev
				return prev.set(offset + prev.length, width, value)
			elif offset >= self.length:
				next = self.next
				return next.set(offset - self.length, width, value)
			elif offset > 0:
				return self.split(offset).set(0, width, value)
			elif offset == 0:
				if width == self.length:
					self.value = value
					return
				elif width < self.length:
					self.split(width)
					return self.set(offset, width, value)
				else:
					return self.merge_for(width).set(offset, width, value)


def place_images(page_width, files):

	def place_image(file):
		width, height = Image.open(file).size
		width = ceil(width)
		if width > page_width:
			raise Exception("Image is wider than page")
		x, y = cursor.write(width, height)
		return Tile(file, x, y, width, height)

	phi = PHI(page_width)
	cursor = phi.cursor()
	tiles = [place_image(file) for file in files]
	height = cursor.reset().read_newline(page_width)
	return height, tiles

def flatten(l):
	for el in l:
		if isinstance(el, collections.Iterable) and not isinstance(el, basestring):
			for sub in flatten(el):
				yield sub
		else:
			yield el

def imagemagick(page_width, page_height, tiles, outfile):
	args = ['/usr/bin/magick']
	args.extend([
		'-size', '{0}x{1}'.format(page_width, page_height),
		'xc:white'])
	for tile in tiles:
		args.extend(['-page', '+{0}+{1}'.format(tile.x, tile.y), tile.file])
	args.extend(['-layers', 'flatten', outfile])

	print(args)

	execv(args[0], args);

def svg_test(page_width, page_height, tiles):
	svg = []
	svg.extend(['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {0} {1}">'.format(page_width, page_height)])
	i=0
	colors = ['rgba(' + rgb + ',0.3)' for rgb in ['255,128,128','255,255,128','128,255,128','128,255,255','128,128,255','255,128,255']]
	for tile in tiles:
		svg.extend(['<rect x="{0}" y="{1}" width="{2}" height="{3}" fill="{4}" stroke="black" stroke-width="20"/>'.format(tile.x, tile.y, tile.width, tile.height, colors[i % len(colors)])])
		svg.extend(['<text x="{0}" y="{1}" fill="black" stroke="black" font-size="50">{2}</text>'.format(tile.x + 100, tile.y + 100, tile.file)])
		i=i+1
	svg.extend(['</svg>'])

	print(''.join(svg))

def main():
	srcdir = environ['annot_dir']
	outfile = environ['output_image']
	page_width = floor(float(environ['page_width']))
	page_height = floor(float(environ['page_height']))

	files = [ join(srcdir, name) for name in listdir(srcdir) if name.endswith('.jpg') and isfile(join(srcdir, name)) ]
	files.sort()

	page_height, tiles = place_images(page_width, files)

	svg_test(page_width, page_height, tiles)

#	imagemagick(page_width, page_height, tiles, outfile)

def test():
	phi = PHI(16)
	print(phi)
	phi.head.set(0, 8, 1)
	print(phi)
	phi.head.set(4, 4, 2)
	print(phi)
	phi.head.set(8, 4, 3)
	print(phi)
	phi.head.set(6, 4, 4)
	print(phi)

	for i in [2,4,6,8,12,16]:
		print("0..{0} : max={1}".format(i, phi.cursor().try_read(i)))


# TODO: replace try_read and friends with
#   y = scan_subrange(offset, width)
# Then we use moving windows to find (offset) such that (y) is
# minimized:
#   y = ẏ(offset_minẏ) using search (offset) to minimize ẏ(offset)
# Breaks ordering a little, but improves column balancing.
# Maybe we should also randomly permute consecutive pairs of photos
# too just to shake up the large ones a bit

# TODO: Split into separate pages also, use page_height envvar

if __name__ == "__main__":
#	test()
	main()
