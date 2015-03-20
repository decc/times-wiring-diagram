require 'csv'

class Gdx
  attr_accessor :gdx_filename
  

  def initialize(gdx_filename)
    @gdx_filename = gdx_filename
    @fraction_of_year_for_timeslice = {}
  end

  def symbol(symbol)
    CSV.new(`gdxdump #{gdx_filename} Symb=#{symbol} Format=csv`, headers: :true, converters: :all, header_converters: :symbol).to_a.map(&:to_hash)
  end

  def load_time_slices
    fraction_of_year_for_timeslice = {}
    symbol(:G_YRFR).each do |row|
      fraction_of_year_for_timeslice[row[:ts]] = row[:val]
    end
    return fraction_of_year_for_timeslice
  end

  def com_units
    return @com_units if @com_units
    @com_units = {}
    symbol(:COM_UNIT).each do |commodity|
      @com_units[commodity[:com]] = commodity[:units_com].to_sym
    end
    @com_units
  end

  def commodity_is_energy?(commodity)
    com_units[commodity] == :PJ
  end

  def simplify_flow_name(flow_name)
    flow_name[/^(.*?)\d*$/,1]
  end

  def load_flows(year)
    flows = Hash.new { |hash, key| hash[key] = 0 } # Hash with default of zero for missing elements
    symbol(:F_IN).each do |flow|
      next unless flow[:allyear] = year
      from = simplify_flow_name(flow[:c])
      next unless commodity_is_energy?(from)
      to = simplify_flow_name(flow[:p])
      amount = flow[:val]
      next if amount == 'Eps'
      flows[[from, to]] += amount
    end
    symbol(:F_OUT).each do |flow|
      next unless flow[:allyear] = year
      from = simplify_flow_name(flow[:p])
      to = simplify_flow_name(flow[:c])
      next unless commodity_is_energy?(to)
      amount = flow[:val]
      next if amount == 'Eps'
      flows[[from, to]] += amount
    end
    flows
  end

  def map_flows_to_d3_format(flows)
    nodes = Hash.new { |hash, key| hash[key] = hash.size }
    links = flows.map do |flow, value|
      {
        source: nodes[flow[0]],
        target: nodes[flow[1]],
        value: value
      }
    end
    nodes = nodes.to_a.sort_by { |a| a[1] }.map { |name, index| { name: name } }
    p nodes.length
    p links.length
    { nodes: nodes, links: links }
  end

end

#puts gdx.map_flows_to_d3_format(gdx.load_flows(2010)).to_json
