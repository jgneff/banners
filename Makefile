# ======================================================================
# Makefile - builds GitHub social previews and Snap featured banners
# Copyright (C) 2021-2022 John Neffenger
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
INKSCAPE = inkscape
LATEXMK  = latexmk
EXIFTOOL = exiftool
MUDRAW   = mutool draw
OPTIPNG  = optipng
PDF2SVG  = pdf2svg
SCOUR    = scour

# Command options
LATEXMK_OPTS = -lualatex
MUDRAW_OPTS  = -r 192
OPTIPNG_OPTS = -quiet
SCOUR_OPTS   = --remove-metadata --indent=none --strip-xml-space \
    --enable-id-stripping --shorten-ids --protect-ids-prefix=surface

# ExifTool options to list the Creative Commons license metadata
exif_xmp := -XMP-cc:all -XMP-dc:all -XMP-xmpRights:all \
    -groupNames1 -veryShort -duplicates

# Sed scripts to edit the XMP metadata for the SVG files
sed_xmp := "s/x:xmpmeta.*>/metadata>/"
sed_jdk := "s/REPO/openjdk/"
sed_jfx := "s/REPO/openjfx/"
sed_mvn := "s/REPO/strictly-maven/"
sed_ide := "s/REPO/strictly-netbeans/"

sed_jdk_social := "s/TITLE/OpenJDK Social Preview/"
sed_jdk_banner := "s/TITLE/OpenJDK Featured Banner/"
sed_jfx_social := "s/TITLE/OpenJFX Social Preview/"
sed_jfx_banner := "s/TITLE/OpenJFX Featured Banner/"
sed_mvn_social := "s/TITLE/Strictly Maven Social Preview/"
sed_mvn_banner := "s/TITLE/Strictly Maven Featured Banner/"
sed_ide_social := "s/TITLE/Strictly NetBeans Social Preview/"
sed_ide_banner := "s/TITLE/Strictly NetBeans Featured Banner/"

# List of targets
openjdk  := $(foreach n,2 3,$(addprefix out/openjdk$(n).,pdf png svg))
openjfx  := $(foreach n,2 3,$(addprefix out/openjfx$(n).,pdf png svg))
maven    := $(foreach n,2 3,$(addprefix out/maven$(n).,pdf png svg))
netbeans := $(foreach n,2 3,$(addprefix out/netbeans$(n).,pdf png svg))

targets := $(openjdk) $(openjfx) $(maven) $(netbeans)

# ======================================================================
# Pattern Rules
# ======================================================================

PDFCMD = $(LATEXMK) $(LATEXMK_OPTS) -output-directory=$(@D) $<

tmp/%.pdf: src/%.svg | tmp
	$(INKSCAPE) --export-pdf=$@ $<

tmp/open%.pdf: src/open%.tex src/preamble.tex tmp/dukewave.pdf
	$(PDFCMD)

tmp/maven%.pdf: src/maven%.tex src/preamble.tex tmp/maven.pdf
	$(PDFCMD)

tmp/netbeans%.pdf: src/netbeans%.tex src/preamble.tex tmp/netbeans.pdf
	$(PDFCMD)

out/%.pdf: tmp/%.pdf tmp/%.xmp | out
	$(EXIFTOOL) -tagsFromFile $(word 2,$^) -out - $< > $@

tmp/%.png: out/%.pdf
	$(MUDRAW) $(MUDRAW_OPTS) -o $@ $<

out/%.png: tmp/%.png tmp/%.xmp
	$(EXIFTOOL) -tagsFromFile $(word 2,$^) -out - $< > $@
	$(OPTIPNG) $(OPTIPNG_OPTS) $@

tmp/%.svg: out/%.pdf
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

.PHONY: all openjdk openjfx maven netbeans list clean

all: $(targets)

openjdk: $(openjdk)

openjfx: $(openjfx)

maven: $(maven)

netbeans: $(netbeans)

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

tmp/maven2.xmp: src/metadata.xmp
	sed -e $(sed_mvn) -e $(sed_mvn_social) $< > $@

tmp/maven3.xmp: src/metadata.xmp
	sed -e $(sed_mvn) -e $(sed_mvn_banner) $< > $@

tmp/netbeans2.xmp: src/metadata.xmp
	sed -e $(sed_ide) -e $(sed_ide_social) $< > $@

tmp/netbeans3.xmp: src/metadata.xmp
	sed -e $(sed_ide) -e $(sed_ide_banner) $< > $@

list: $(targets)
	$(EXIFTOOL) $(exif_xmp) $^

clean:
	rm -f tmp/* out/*
