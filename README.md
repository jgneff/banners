This project creates two sets of images for each of the following projects:

* [OpenJDK](https://github.com/jgneff/openjdk) - Current JDK release and early-access builds
* [OpenJFX](https://github.com/jgneff/openjfx) - Current JavaFX release and early-access builds
* [Strictly Maven](https://github.com/jgneff/strictly-maven) - Apache Maven™ in a strictly-confined snap
* [Strictly NetBeans](https://github.com/jgneff/strictly-netbeans) - Apache NetBeans® in a strictly-confined snap

The two sets of images are created in PDF, PNG, and SVG formats for:

* the GitHub social media preview in a 2:1 aspect ratio, and
* the Snap Store featured banner in a 3:1 aspect ratio.

## Building

Build the images with the `make` command in the root directory of the project. The final images are created in the `out` directory. See the top of the [Makefile](Makefile) for the list of required programs.

## License

The following files are derived from their original versions on Wikimedia Commons and licensed as follows:

* src/dukewave.svg - from [Duke (Java mascot) waving.svg](https://commons.wikimedia.org/wiki/File:Duke_(Java_mascot)_waving.svg) under the BSD 3-Clause License
* src/maven.svg - from [Apache Maven logo.svg](https://commons.wikimedia.org/wiki/File:Apache_Maven_logo.svg) under the Apache License 2.0
* src/netbeans.svg - from [Apache NetBeans Logo.svg](https://commons.wikimedia.org/wiki/File:Apache_NetBeans_Logo.svg) under the Apache License 2.0

All of the other files in this repository are licensed under the [GNU General Public License v3.0](LICENSE).

The PDF, PNG, and SVG images created by this project are licensed under the [Creative Commons Attribution-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-sa/4.0/).
