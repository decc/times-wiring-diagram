require_relative 'gdx'

unless ARGV[0] && File.exist?(ARGV[0])
  puts "Usage:"
  puts "ruby update-flow-diagram.rb <GAMS-GDX-FILE.gdx> <year> <description>"
  puts "where the gdx file is usual found in the VEDA_FE/GAMS_WrkTIMES/GamsSave folder, with the same name as the scenario that has been run"
  puts "n.b.: this means you have to run a scenario with the TIMES model before attempting this"
  puts "<year> is the year for which you want the flow diagram drawn"
  puts "<description> is added to the output, good things to put here are the version number of the TIMES model"
  exit
end

year = ARGV[1].to_i
title = "#{year} Energy flow diagram for TIMES #{ARGV[2]}"

threshold = 10 # Do not show flows with less energy (in PJ) than this
pen_thickness_per_pj = 0.01 # Scale the thickness of lines in proportion to PJ

# First we load the gdx file
puts "Opening #{ARGV[0]}"
gdx = Gdx.new(ARGV[0])

# Then we extract the flows
# The choice of 2010 is, I think arbitrary
puts "Extracting flows"
flows = gdx.load_flows(year)

# Create the Node objects
puts "Analysing nodes"
class Node
  attr_accessor :in, :out, :name
  attr_accessor :in_size, :out_size

  def initialize(name)
    @name = name
    @in, @out = [], []
    @in_size, @out_size = 0.0, 0.0
  end
  def primary_source
    @in.empty? && !@out.empty?
  end
  def final_demand
    @out.empty? && !@in.empty?
  end
  def size
    [@in_size, @out_size].max
  end
end

nodes = Hash.new { |hash, key| hash[key] = Node.new(key) }

# We do this so we can put all the sources of energy and final demands
# on the same horizontal row in the final diagram
puts "Finding primary sources of energy and final demands for energy"
flows.each do |flow, value|
  h = nodes[flow[0].gsub(/[^a-zA-Z0-9]+/,'')]
  t = nodes[flow[1].gsub(/[^a-zA-Z0-9]+/,'')]
  next if t == h
  h.out.push(t)
  h.out_size += value
  t.in.push(h) 
  t.in_size += value
end

# Then we open up a Graphviz input file:
puts "Writing Graphviz input file"
File.open('flow.gv', 'w') do |f|
  # The Graphviz format is described here:
  # http://www.graphviz.org/
  f.puts "digraph flows {" # We have a directed graph (or at least, in a sensible energy system we should"
  f.puts 'graph [rankdir="LR", ratio=0.7, arrowhead="none"]' # We want the result to look square-ish
  f.puts 'node [shape="box", id="\N"]' # We want the result to look square-ish
  f.puts 'edge [id="\T_\H"]' # We want the result to look square-ish
  f.puts "{rank=source; #{nodes.values.select(&:primary_source).map(&:name).join(' ')} }"
  f.puts "{rank=sink; #{nodes.values.select(&:final_demand).map(&:name).join(' ')} }"

  nodes.values.each do |n|
    f.puts "#{n.name} [height=#{(n.size*pen_thickness_per_pj/50).round}];"
  end

  flows.each do |flow, value| # We write out each flow in the Graphviz format
    next if value.abs < threshold # Skip the small flows
    # We have to make sure that the node names don't include anything but letters and digits
    f.puts "#{flow[0].gsub(/[^a-zA-Z0-9]+/,'')} -> #{flow[1].gsub(/[^a-zA-Z0-9]+/,'')} [weight=#{value.round}, penwidth=#{(value*pen_thickness_per_pj).round}];"
  end
  
  f.puts "}"
end

# Now we process the Graphviz input file into svg
# -T svg means write the result as svg
# -o flows.svg gives the output filename
puts "Processing graphviz file"
puts `dot -o flow.svg -T svg flow.gv`

# Now we open the svg file
puts "Loading resulting svg"
svg = IO.readlines('flow.svg')

# Now we drop all the gumph at the head of the file until
# we hit the first bit of drawing
svg.shift until svg.first =~ /^<g/
svg.delete_if { |line| line =~ /^<polygon fill="black/ } # some polygons get in the way

# Now we embed the svg in a template
html = <<END
<html>
<meta http-equiv="X-UA-Compatible" content="IE=Edge" />
<meta charset='utf-8'>
<title>#{title}</title>
<style>
  h1 {
    width: 100%;
    text-align: center;
    size: 10px;
    margin: 0;
    padding: 0;
  }
  g.node {
    pointer-events: all;
  }
  .highlight polygon {
    fill: #ff0;
    stroke: #f00;
    stroke-width: 4px;
  }
  .highlight path {
    stroke: #f00;
  }
</style>
<script src='d3.min.js'></script>
<script src='svg-pan-zoom.min.js'></script>
<body>
<h1>#{title}</h1>
<svg id='nodeplot'>
#{svg.join}
<script>
var margin = {top: 20, right: 20, bottom: 30, left: 50},
    width = window.innerWidth - margin.left - margin.right,
    height = window.innerHeight - margin.top - margin.bottom;

d3.select('#nodeplot')
  .attr('width', width)
  .attr('height', height);

d3.selectAll(".edge")
  .attr("class", function(d) { return 'edge '+(this.id.replace('_', ' ')); });

d3.selectAll(".node")
  .attr("class", function(d) { return 'node '+(this.id); });

d3.selectAll("g.node").on('click',function(d) {
    if( d3.select(this).classed('highlight')) {
      d3.selectAll("."+this.id).classed('highlight', false);
    } else {
      d3.selectAll("."+this.id).classed("highlight", true);
    }
    d3.event.preventDefault();
    });

var panZoomTiger = svgPanZoom('#nodeplot', {
  controlIconsEnabled: true,
  zoomEnabled: true,
  maxZoom: 50
});
</script>
</html>
END

# Now we write that out to a file
puts "Writing webpage"
File.open('flow.html','w') { |f| f.puts html }

# And we are done
puts "Done"

