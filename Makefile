# ======================================================================
# Makefile - builds GitHub social previews and Snap featured banners
# Copyright (C) 2021 John Neffenger
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# ======================================================================

# Commands
CONVERT  = convert
MKBITMAP = mkbitmap
POTRACE  = potrace
LATEXMK  = latexmk
EXIFTOOL = exiftool
MUDRAW   = mutool draw
OPTIPNG  = optipng
INKSCAPE = inkscape
PDF2SVG  = pdf2svg
SCOUR    = scour

# Java logo colors
java_blue   = --color "\#007396"
java_orange = --color "\#ed8b00"

# Command options (mkbitmap defaults: -f 4 -s 2 -3 -t 0.45)
MKBITMAP_OPTS = --filter 16 --scale 2 --cubic --threshold 0.45
POTRACE_OPTS  = --backend pdf $(java_blue) --resolution 90 --turdsize 2
LATEXMK_OPTS  = -lualatex
MUDRAW_OPTS   = -r 192
OPTIPNG_OPTS  = -quiet
SCOUR_OPTS    = --remove-metadata --indent=none --strip-xml-space \
    --enable-id-stripping --shorten-ids

# ExifTool options to list the Creative Commons license metadata
exif_xmp := -XMP-cc:all -XMP-dc:all -XMP-xmpRights:all \
    -groupNames1 -veryShort -duplicates

# Sed scripts to edit the XMP metadata for the SVG files
sed_xmp := "s/x:xmpmeta.*>/metadata>/"
sed_jdk := "s/REPO/openjdk/"
sed_jfx := "s/REPO/openjfx/"

sed_jdk_social := "s/TITLE/OpenJDK Social Preview/"
sed_jdk_banner := "s/TITLE/OpenJDK Featured Banner/"
sed_jfx_social := "s/TITLE/OpenJFX Social Preview/"
sed_jfx_banner := "s/TITLE/OpenJFX Featured Banner/"

# List of targets
targets := $(addprefix out/openjdk2.,pdf png svg)
targets += $(addprefix out/openjdk3.,pdf png svg)
targets += $(addprefix out/openjfx2.,pdf png svg)
targets += $(addprefix out/openjfx3.,pdf png svg)

# ======================================================================
# Pattern Rules
# ======================================================================

.PRECIOUS: tmp/dukewave.pdf

tmp/%.ppm: src/%.gif | tmp
	$(CONVERT) $< $@

tmp/%.pbm: tmp/%.ppm
	$(MKBITMAP) $(MKBITMAP_OPTS) --output $@ $<

tmp/%.pdf: tmp/%.pbm
	$(POTRACE) $(POTRACE_OPTS) --output $@ $<

tmp/%.pdf: src/%.tex src/preamble.tex tmp/dukewave.pdf
	$(LATEXMK) $(LATEXMK_OPTS) -output-directory=$(@D) $<

out/%.pdf: tmp/%.pdf tmp/%.xmp | out
	$(EXIFTOOL) -tagsFromFile $(word 2,$^) -out - $< > $@

tmp/%.png: out/%.pdf
	$(MUDRAW) $(MUDRAW_OPTS) -o $@ $<

out/%.png: tmp/%.png tmp/%.xmp
	$(EXIFTOOL) -tagsFromFile $(word 2,$^) -out - $< > $@
	$(OPTIPNG) $(OPTIPNG_OPTS) $@

tmp/%.svg: out/%.pdf
#	$(INKSCAPE) --export-plain-svg=$@ $<
	$(PDF2SVG) $< $@

tmp/%-scour.svg: tmp/%.svg
	$(SCOUR) -i $< -o $@ $(SCOUR_OPTS)

tmp/%.xml: tmp/%.xmp
	sed $(sed_xmp) $< > $@

out/%.svg: tmp/%-scour.svg tmp/%.xml src/svgstyle.css
	sed -e "/<svg/r $(word 2,$^)" -e "/<svg/r $(word 3,$^)" $< > $@

# ======================================================================
# Explicit rules
# ======================================================================

.PHONY: all list clean

all: $(targets)

tmp out:
	mkdir -p $@

tmp/openjdk2.xmp: src/metadata.xmp
	sed -e $(sed_jdk) -e $(sed_jdk_social) $< > $@

tmp/openjdk3.xmp: src/metadata.xmp
	sed -e $(sed_jdk) -e $(sed_jdk_banner) $< > $@

tmp/openjfx2.xmp: src/metadata.xmp
	sed -e $(sed_jfx) -e $(sed_jfx_social) $< > $@

tmp/openjfx3.xmp: src/metadata.xmp
	sed -e $(sed_jfx) -e $(sed_jfx_banner) $< > $@

list: $(targets)
	$(EXIFTOOL) $(exif_xmp) $^

clean:
	rm -f tmp/* out/*
