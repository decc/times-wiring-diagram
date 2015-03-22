require_relative 'gdx'

unless ARGV[0] && File.exist?(ARGV[0])
  puts "Usage:"
  puts "ruby update-wiring-diagram.rb <GAMS-GDX-FILE.gdx> <description>"
  puts "where the gdx file is usual found in the VEDA_FE/GAMS_WrkTIMES/GamsSave folder, with the same name as the scenario that has been run"
  puts "n.b.: this means you have to run a scenario with the TIMES model before attempting this"
  puts "<description> is added to the output, good things to put here are the version number of the TIMES model"
  exit
end

# First we load the gdx file
puts "Opening #{ARGV[0]}"
gdx = Gdx.new(ARGV[0])

# Then we extract the flows
# The choice of 2010 is, I think arbitrary
puts "Extracting flows"
flows = gdx.load_flows(2010)

# Then we open up a Graphviz input file:
puts "Writing Graphviz input file"
File.open('wiring.gv', 'w') do |f|
  # The Graphviz format is described here:
  # http://www.graphviz.org/
  f.puts "digraph flows {" # We have a directed graph (or at least, in a sensible energy system we should"
  f.puts "graph [ratio=1]" # We want the result to look square-ish
  f.puts 'node [id="\N"]' # We want the result to look square-ish
  f.puts 'edge [id="\T_\H"]' # We want the result to look square-ish

  flows.map do |flow, value| # We write out each flow in the Graphviz format
    # We have to make sure that the node names don't include anything but letters and digits
    f.puts "#{flow[0].gsub(/[^a-zA-Z0-9]+/,'')} -> #{flow[1].gsub(/[^a-zA-Z0-9]+/,'')};"
  end
  
  f.puts "}"
end

# Now we process the Graphviz input file into svg
# -T svg means write the result as svg
# -o flows.svg gives the output filename
puts "Processing graphviz file"
puts `dot -o wiring.svg -T svg wiring.gv`

# Now we open the svg file
puts "Loading resulting svg"
svg = IO.readlines('wiring.svg')

# Now we drop all the gumph at the head of the file until
# we hit the first bit of drawing
svg.shift until svg.first =~ /^<g/

# Now we embed the svg in a template
html = <<END
<html>
<meta http-equiv="X-UA-Compatible" content="IE=Edge" />
<meta charset='utf-8'>
<style>
  h1 {
    width: 100%;
    text-align: center;
    size: 15px;
    margin: 0;
    padding: 0;
  }
  g.node {
    pointer-events: all;
  }
  .highlight ellipse {
    fill: #ff0;
    stroke: #f00;
    stroke-width: 4px;
  }
  .highlight path {
    stroke: #f00;
    stroke-width: 4px;
  }
</style>
<script src='d3.min.js'></script>
<script src='svg-pan-zoom.min.js'></script>
<body>
<h1>Energy wiring diagram for TIMES #{ARGV[1]}</h1>
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
File.open('index.html','w') { |f| f.puts html }

# And we are done
puts "Done"

