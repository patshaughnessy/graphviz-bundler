BUNDLER_DEBUG_OUTPUT = '../test1/output.txt'

require 'rubygems'
require 'graphviz'

class AssociationsGraph

  def generate_one(gems, file_name)
    graph_viz = GraphViz::new('Gemfile', {:concentrate => true, :normalize => true, :nodesep => 0.55})
    graph_viz.edge[:fontname] = graph_viz.node[:fontname] = 'Arial, Helvetica, SansSerif'
    graph_viz.edge[:fontsize] = 12
    graph_viz.edge[:arrowhead] = 'none'

    activated_nodes = []
    activated_nodes[0] = graph_viz.add_node('Activated', { :shape => 'box3d', :fontsize => 16, :style => 'filled', :fillcolor => '#B9B9D5'} )

    activated_count = 1
    gems[:activated].each do |gem|
      activated_nodes[activated_count] = graph_viz.add_node(gem, { :fontsize => 16, :style => 'filled', :fillcolor => '#FFFFFF'} )
      graph_viz.add_edge( activated_nodes[activated_count-1], activated_nodes[activated_count], { :weight => 2 } )
      activated_count += 1
    end

    requirement_nodes = []
    requirement_nodes[0] = graph_viz.add_node('Requirements', { :shape => 'box3d', :fontsize => 16, :style => 'filled', :fillcolor => '#B9B9D5'} )

    requirement_count = 1
    gems[:requirements].each do |gem|
      requirement_nodes[requirement_count] = graph_viz.add_node(gem, { :fontsize => 16, :style => 'filled', :fillcolor => '#FFFFFF'} )
      graph_viz.add_edge( requirement_nodes[requirement_count-1], requirement_nodes[requirement_count], { :weight => 2 } )
      requirement_count += 1
    end

    graph_viz.output( :png => file_name )
  end

  def generate_two(gems, file_name)

    graph_viz = GraphViz::new('Gemfile', {:concentrate => true, :normalize => true, :nodesep => 0.55})
    graph_viz.edge[:fontname] = graph_viz.node[:fontname] = 'Arial, Helvetica, SansSerif'
    graph_viz.edge[:fontsize] = 12

    dependency_nodes = []
    dependency_nodes[0] = graph_viz.add_node("Try: #{gems[:activating][0]}", { :shape => 'box3d', :fontsize => 16, :style => 'filled', :fillcolor => '#B9B9D5'} )

    dependency_count = 1
    gems[:dependencies].each do |gem|
      dependency_nodes[dependency_count] = graph_viz.add_node("Dependency:\n#{gem}", { :fontsize => 16, :style => 'filled', :fillcolor => '#FFFFFF'} )
      graph_viz.add_edge( dependency_nodes[0], dependency_nodes[dependency_count], { :weight => 2 } )
      dependency_count += 1
    end

    graph_viz.output( :png => file_name )
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
      when /Activating:\s(.*)$/
        type = :activating
        gems[type] << $1
        puts "DEBUG added activating #{$1}"
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
    puts "Iteration: #{count}; process #{lines.size} lines. Activate count: #{gems[:activated].size}"
    generate_one(gems, "first#{count}.png") if count < 10
    generate_two(gems, "second#{count}.png") if count < 10
  end
end

iteration_lines = []
grapher = AssociationsGraph.new
File.open(ARGV[0]).each do |line|
  if line =~ /==== Iterating ====/
    grapher.process iteration_lines unless iteration_lines == []
    iteration_lines = []
  else
    iteration_lines << line
  end
end
grapher.process iteration_lines unless iteration_lines == []
