BUNDLER_DEBUG_OUTPUT = '../test1/output.txt'

require 'rubygems'
require 'graphviz'

class AssociationsGraph

  def generate(gems, file_name)
    puts 'Generating graph...'
    graph_viz = GraphViz::new('Gemfile', {:concentrate => true, :normalize => true, :nodesep => 0.55})
    graph_viz.edge[:fontname] = graph_viz.node[:fontname] = 'Arial, Helvetica, SansSerif'
    graph_viz.edge[:fontsize] = 12

    nodes = {}
    gems[:activated].each do |gem|
      nodes[gem] = graph_viz.add_node(gem, { :shape => 'box3d', :fontsize => 16, :style => 'filled', :fillcolor => '#B9B9D5'} )
    end

#    each_model do |model|
#      name = model.to_s
#      model.reflect_on_all_associations.each do |assoc|
#        graph_viz.add_edge( models[name], models[assoc.name.to_s.singularize.titleize], { :weight => 2 } )
#      end
#    end

    graph_viz.output( :png => file_name )

    puts 'Done.'
  end

  def initialize
    @count = 0
  end

  attr_reader :count

  def next_count
    @count += 1
  end

  def process(lines)
    next_count
    puts "Iteration: #{count}; process #{lines.size} lines. "

    gems = Hash.new { |hash, key| hash[key] = [] }
    type = :none
    lines.each do |line|
      case line
      when /Activated:/
        type = :activated
      when /Requirements:/
        type = :requirements
      when /Attempting:/
        type = :attempting
      when /Activating:/
        type = :activating
      when /Dependencies/
        type = :dependencies
      else
        if type == :dependencies
          gems[type] << line.strip.split(' ')[1..-1].join(' ')
        else
          gems[type] << line.strip unless type == :none
        end
      end
    end
    generate(gems, "test#{count}.png")
  end
end

iteration_lines = []
grapher = AssociationsGraph.new
File.open(BUNDLER_DEBUG_OUTPUT).each do |line|
  if line =~ /==== Iterating ====/
    grapher.process iteration_lines unless iteration_lines == []
    iteration_lines = []
  else
    iteration_lines << line
  end
end
grapher.process iteration_lines unless iteration_lines == []
