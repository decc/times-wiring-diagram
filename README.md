# Energy Wiring Diagram Generator for UK TIMES

This code generates wiring diagrams for the energy flows in UK TIMES. 

i.e., it shows natural gas being connected to imports and to electricity generation and to heating


Relies on: 

1. the excellent [Graphviz](http://graphviz.org) visualisation library
2. the excellent [svg-pan-zoom](https://github.com/ariutta/svg-pan-zoom) javascript library.
3. the excellent [d3](http://d3js.org) visualisation library

&copy; 2015 Tom Counsell http://tom.counsell.org

## Usage

You need to have installed:

1. Ruby
2. Graphviz

You need to have run the TIMES scenario, and found the resulting gdx file. This is usually in VEDA_FE/GAMS_WrkTIMES/GamsSave folder, with the same name as the scenario that has been run.

Then you run:

    ruby update-wiring-diagram.rb <GAMS-GDX-FILE.gdx> <description>

Where description is anything you like. The version of the TIMES database being tested is a good thing to say.

## Hacking

Authoritative copy at http://github.com/decc/times-wiring-diagram

Please report issues there.

## TODO

1. A way of searching for a particular node then highlighting it and zooming to it
2. A way of following links to or from a node

## License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

