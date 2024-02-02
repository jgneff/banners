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

# Sets 'CreationDate' of 'rsvg-convert' output for reproducible builds
export SOURCE_DATE_EPOCH := $(shell git log -1 --pretty=%ct)

# Commands
LIBRSVG  = rsvg-convert
LATEXMK  = latexmk
EXIFTOOL = exiftool
PDF2SVG  = pdf2svg
SCOUR    = scour
OPTIPNG  = optipng

# Command options
SVG2PDF_OPTS = --format=pdf
# Background color from Firefox "Open Image in New Tab"
# chrome://global/skin/media/imagedoc-darknoise.png
SVG2PNG_OPTS = --zoom=2 --background-color=\#222222
LATEXMK_OPTS = -lualatex
SCOUR_OPTS   = --remove-metadata --indent=none --strip-xml-space \
    --enable-id-stripping --protect-ids-prefix=surface
OPTIPNG_OPTS = -quiet

# Options for Duke Waving (original SVG is 225.94 × 407.41 px)
duke2pdf = --format=pdf \
    --page-width=232 --page-height=414 --top=3 --left=3
duke2png = --format=png --height=500 --keep-aspect-ratio \
    --page-width=512 --page-height=512 --top=6 --left=117

# ExifTool options to list the Creative Commons license metadata
exif_xmp := -XMP-cc:all -XMP-dc:all -XMP-xmpRights:all \
    -groupNames1 -veryShort -duplicates

# Sed scripts to edit the XMP metadata for the SVG files
sed_xmp := "s/x:xmpmeta.*>/metadata>/"
sed_jdk := "s/REPO/openjdk/"
sed_jfx := "s/REPO/openjfx/"
sed_mvn := "s/REPO/strictly-maven/"
sed_ide := "s/REPO/strictly-netbeans/"
sed_duke := "s/REPO/banners/"

sed_jdk_social := "s/TITLE/OpenJDK Social Preview/"
sed_jdk_banner := "s/TITLE/OpenJDK Featured Banner/"
sed_jfx_social := "s/TITLE/OpenJFX Social Preview/"
sed_jfx_banner := "s/TITLE/OpenJFX Featured Banner/"
sed_mvn_social := "s/TITLE/Strictly Maven Social Preview/"
sed_mvn_banner := "s/TITLE/Strictly Maven Featured Banner/"
sed_ide_social := "s/TITLE/Strictly NetBeans Social Preview/"
sed_ide_banner := "s/TITLE/Strictly NetBeans Featured Banner/"
sed_duke_icon  := "s/TITLE/Duke Waving Icon/"

# List of targets
openjdk  := $(foreach n,2 3,$(addprefix out/openjdk$(n).,pdf png svg))
openjfx  := $(foreach n,2 3,$(addprefix out/openjfx$(n).,pdf png svg))
maven    := $(foreach n,2 3,$(addprefix out/maven$(n).,pdf png svg))
netbeans := $(foreach n,2 3,$(addprefix out/netbeans$(n).,pdf png svg))

targets := $(openjdk) $(openjfx) $(maven) $(netbeans) out/dukewave.png

# ======================================================================
# Pattern Rules
# ======================================================================

PDFCMD = $(LATEXMK) $(LATEXMK_OPTS) -output-directory=$(@D) $<

# Makes PDF files

tmp/%.pdf: src/%.svg | tmp
	$(LIBRSVG) $(SVG2PDF_OPTS) --output=$@ $<

tmp/open%.pdf: src/open%.tex src/preamble.tex tmp/dukewave.pdf
	$(PDFCMD)

tmp/maven%.pdf: src/maven%.tex src/preamble.tex tmp/maven.pdf
	$(PDFCMD)

tmp/netbeans%.pdf: src/netbeans%.tex src/preamble.tex tmp/netbeans.pdf
	$(PDFCMD)

out/%.pdf: tmp/%.pdf tmp/%.xmp | out
	$(EXIFTOOL) -tagsFromFile $(word 2,$^) -out - $< > $@

# Makes SVG files

tmp/%.svg: out/%.pdf
	$(PDF2SVG) $< $@

tmp/%-scour.svg: tmp/%.svg
	$(SCOUR) -i $< -o $@ $(SCOUR_OPTS)

tmp/%.xml: tmp/%.xmp
	sed $(sed_xmp) $< > $@

out/open%.svg: tmp/open%-scour.svg tmp/open%.xml src/svgopen.css
	sed -e "/<svg/r $(word 2,$^)" -e "/<svg/r $(word 3,$^)" $< > $@

out/%.svg: tmp/%-scour.svg tmp/%.xml src/svgauth.css
	sed -e "/<svg/r $(word 2,$^)" -e "/<svg/r $(word 3,$^)" $< > $@

# Makes PNG files

tmp/open%.png: out/open%.svg src/pngopen.css
	$(LIBRSVG) $(SVG2PNG_OPTS) --stylesheet=$(word 2,$^) --output=$@ $<

tmp/%.png: out/%.svg src/pnguser.css
	$(LIBRSVG) $(SVG2PNG_OPTS) --stylesheet=$(word 2,$^) --output=$@ $<

out/%.png: tmp/%.png tmp/%.xmp
	$(EXIFTOOL) -tagsFromFile $(word 2,$^) -out - $< > $@
	$(OPTIPNG) $(OPTIPNG_OPTS) $@

# ======================================================================
# Explicit rules
# ======================================================================

.PHONY: all openjdk openjfx maven netbeans list clean

all: $(targets)

openjdk: $(openjdk)

openjfx: $(openjfx)

maven: $(maven)

netbeans: $(netbeans)

tmp out:
	mkdir -p $@

tmp/dukewave.pdf: src/dukewave.svg | tmp
	$(LIBRSVG) $(duke2pdf) --output=$@ $<

tmp/dukewave.png: src/dukewave.svg src/pngduke.css
	$(LIBRSVG) $(duke2png) --stylesheet=$(word 2,$^) --output=$@ $<

tmp/openjdk2.xmp: src/metadata.xmp
	sed -e $(sed_jdk) -e $(sed_jdk_social) $< > $@

tmp/openjdk3.xmp: src/metadata.xmp
	sed -e $(sed_jdk) -e $(sed_jdk_banner) $< > $@

tmp/openjfx2.xmp: src/metadata.xmp
	sed -e $(sed_jfx) -e $(sed_jfx_social) $< > $@

tmp/openjfx3.xmp: src/metadata.xmp
	sed -e $(sed_jfx) -e $(sed_jfx_banner) $< > $@

tmp/maven2.xmp: src/metadata.xmp
	sed -e $(sed_mvn) -e $(sed_mvn_social) $< > $@

tmp/maven3.xmp: src/metadata.xmp
	sed -e $(sed_mvn) -e $(sed_mvn_banner) $< > $@

tmp/netbeans2.xmp: src/metadata.xmp
	sed -e $(sed_ide) -e $(sed_ide_social) $< > $@

tmp/netbeans3.xmp: src/metadata.xmp
	sed -e $(sed_ide) -e $(sed_ide_banner) $< > $@

tmp/dukewave.xmp: src/metadata.xmp
	sed -e $(sed_duke) -e $(sed_duke_icon) $< > $@

list: $(targets)
	$(EXIFTOOL) $(exif_xmp) $^

clean:
	rm -f tmp/* out/*
