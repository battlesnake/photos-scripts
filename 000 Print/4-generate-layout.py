#!/bin/false

from os import listdir, environ, fork, execv, waitpid
from os.path import isfile, join
from PIL import Image
from math import ceil, floor
from copy import copy
from itertools import groupby

# Image tile
class Tile:

	def __init__(self, file, x, y, width, height, page):
		self.file = file
		self.x = x
		self.y = y
		self.width = width
		self.height = height
		self.page = page

# Piecewise horizontal interval
class PiecewiseHorizontalInterval:

	def __init__(self, width):
		self.head = PiecewiseHorizontalInterval.HorizontalInterval(width)

	def __str__(self):
		return self.head.__str__()

	def random_cursor(self):
		return PiecewiseHorizontalInterval.RandomCursor(self.head)

	def sequential_cursor(self):
		return PiecewiseHorizontalInterval.SequentialCursor(self.head)

	# Cursor for randomly reading/writing to the range
	# Finds the upper-most area that can accommodate the given dimensions
	# Vertically, tiles will mostly appear ordered, however within a "row",
	# any apparent ordering is coincidental.
	class RandomCursor:

		def __init__(self, head):
			self.head = head
			self.reset()

		def reset(self):
			return

		def read(self, position, length):
			# Seek
			if isinstance(position, PiecewiseHorizontalInterval.HorizontalInterval):
				item = position
				offset = 0
				target = length - 1
			else:
				item = self.head
				offset = 0
				while position >= offset + item.length:
					offset += item.length
					item = item.next
					if item is None:
						raise Exception("Seek out of range")
				target = position + length - 1
			# Read
			max = None
			while offset < target:
				if max is None or item.value > max:
					max = item.value
				offset += item.length
				item = item.next
				if item is None and offset < target:
					return None
			return max

		def find(self, length):
			item = self.head
			min = None
			position = 0
			while item is not None:
				max = self.read(item, length)
				if max is None:
					break
				if min is None or max < min[2]:
					min = [item, position, max]
				position += item.length
				item = item.next
			return min

		def place(self, length, delta_y):
			item, position, y = self.find(length)
			y_new = y + delta_y
			item.set(0, length, y_new)
			return [position, y]

	# Cursor for sequentially reading/writing to the range
	# Moved right, then down, to find a space that can fit the given dimensions.
	# Stores last position between calls, and moves from that position during
	# read/write.
	# Tiles will appear ordered.
	class SequentialCursor:

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

		# Moves the sequential_cursor by the given amount.
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

		def place(self, delta_x, delta_y):
			dup = copy(self)
			y = dup.try_read(delta_x)
			if y is None:
				dup.reset()
				y = dup.try_read(delta_x)
				self.reset()
				if y is None:
					raise Exception("Placement failed")
			res = [self.position, y]
			self.current.set(self.offset, delta_x, y + delta_y)
			if self.try_read(delta_x) is None:
				raise Exception("Placement failed")
			return res

	# Horizontal interval (double linked-list)
	# The various methods may modify the list head's properties, but they will
	# never invalidate the list head's reference.
	class HorizontalInterval:

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

		# Removes subrange
		def remove(self):
			if self.prev is None:
				raise Exception("Cannot remove list head")
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
			return PiecewiseHorizontalInterval.HorizontalInterval(rlength, self.value, self)

		# Merges subrange into next if the increase in length does not exceed
		# maxgrowth.  The resulting interval taks the maximum value of the
		# merged intervals.  Return value is Δlength
		def merge_next(self, maxgrowth = -1):
			if maxgrowth == 0:
				return 0
			if self.next is None:
				raise Exception("Cannot merge, subrange is last in range")
			growth = self.next.length
			if growth > maxgrowth:
				return 0
			self.value = max(self.value, self.next.value)
			self.length += self.next.length
			self.next.remove()
			return growth

		# Merges repeatedly until we have reached a certain length
		def merge_length(self, length):
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

		# Set the value of a subrange, relative to the start of this subrange
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
					return self.merge_length(width).set(offset, width, value)

def place_images(page_width, page_height, files, preserve_order = True):

	# To get around the scoping rules
	class page_counter:
		def __init__(self): self.page = 0
		def next(self): self.page += 1
		def get(self): return self.page

	page = page_counter()
	interval = PiecewiseHorizontalInterval(page_width)
	cursor = interval.sequential_cursor() if preserve_order else interval.random_cursor()

	def image_size(file):
		width, height = Image.open(file).size
		if width > page_width:
			raise Exception("Image is wider than page")
		if height > page_height:
			raise Exception("Image is taller than page")
		return [width, height]

	def place_image(file):
		width, height = image_size(file)
		x, y = cursor.place(width, height)
		if y + height > page_height:
			page.next()
			interval.head.set(0, page_width, 0)
			cursor.reset()
			return place_image(file)
		return Tile(file, x, y, width, height, page.get())

	return [place_image(file) for file in files]

def render_pages(page_width, page_height, tiles, outfile):

	def magick(args):
		args = ['/usr/bin/magick'] + args
		pid = fork()
		if pid == 0:
			execv(args[0], args)
		else:
			waitpid(pid, 0)

	page_num = lambda tile: tile.page
	npages = max(tiles, key = page_num).page + 1

	for page, tiles in groupby(sorted(tiles, key = page_num), key = page_num):
		args = []
		args.extend([
			'-size', '{0}x{1}'.format(page_width, page_height),
			'xc:white',
			'-gravity', 'northwest'
		])
		for tile in tiles:
			args.extend(['(',
				tile.file,
				'-geometry', '+{0}+{1}'.format(tile.x, tile.y),
			')',
			'-composite'])
		args.append(outfile % page)
		print("Rendering page {0}/{1}".format(page + 1, npages))
		magick(args)

def render_svg_layout(page_width, page_height, tiles, layoutfile):
	page_spacing = page_width * 0.1
	page_delta_x = page_width + page_spacing
	npages = max(tiles, key = lambda tile: tile.page).page + 1
	svg = []
	svg.extend(['<svg xmlns="http://www.w3.org/2000/svg" viewBox="{0} {0} {1} {2}">'.format(-page_spacing, page_delta_x * npages + page_spacing, page_height + page_spacing * 2)])
	colors = ['rgba(' + rgb + ',0.3)' for rgb in ['255,128,128','255,255,128','128,255,128','128,255,255','128,128,255']]
	for page in range(npages):
		svg.extend(['<rect x="{0}" y="{1}" width="{2}" height="{3}" fill="#eee" stroke="black" stroke-width="20"/>'.format(page_delta_x * page, 0, page_width, page_height)])
	for tile in tiles:
		svg.extend(['<rect x="{0}" y="{1}" width="{2}" height="{3}" fill="white" stroke="none"/>'.format(tile.x + page_delta_x * tile.page, tile.y, tile.width, tile.height)])
	for i, tile in enumerate(tiles):
		svg.extend(['<rect x="{0}" y="{1}" width="{2}" height="{3}" fill="{4}" stroke="black" stroke-width="20"/>'.format(tile.x + page_delta_x * tile.page, tile.y, tile.width, tile.height, colors[i % len(colors)])])
		svg.extend(['<text x="{0}" y="{1}" fill="black" stroke="black" font-size="50">{2}</text>'.format(tile.x + page_delta_x * tile.page + 100, tile.y + 100, tile.file)])
		svg.extend(['<text text-anchor="middle" dy="0.5em" x="{0}" y="{1}" fill="black" stroke="black" font-size="500">{2}</text>'.format(tile.x + page_delta_x * tile.page + tile.width/2, tile.y + tile.height/2, str(i))])
	svg.extend(['</svg>'])

	svg_file = open(layoutfile, "w")
	svg_file.write(''.join(svg))
	svg_file.close()

def main():
	srcdir = environ['annot_dir']
	outfile = environ['output_image']
	layoutfile = environ['layout_image']
	page_width = floor(float(environ['page_width']))
	page_height = floor(float(environ['page_height']))
	preserve_order = environ['preserve_order'].lower() in ['true', 'yes', '1']

	files = [ join(srcdir, name) for name in listdir(srcdir) if name.endswith('.jpg') and isfile(join(srcdir, name)) ]
	files.sort()

	tiles = place_images(page_width, page_height, files, preserve_order)

	render_svg_layout(page_width, page_height, tiles, layoutfile)

	render_pages(page_width, page_height, tiles, outfile)

def test():
	interval = PiecewiseHorizontalInterval(16)
	print(interval)
	interval.head.set(0, 8, 1)
	print(interval)
	interval.head.set(4, 4, 2)
	print(interval)
	interval.head.set(8, 4, 3)
	print(interval)
	interval.head.set(6, 4, 4)
	print(interval)

	for i in [2,4,6,8,12,16]:
		print("0..{0} : max={1}".format(i, interval.sequential_cursor().try_read(i)))


if __name__ == "__main__":
#	test()
	main()
