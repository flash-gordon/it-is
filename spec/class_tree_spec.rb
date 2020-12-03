require 'active_support/descendants_tracker'
require 'set'

RSpec.describe 'work with class inheritance tree' do
  constants = %w(Foo Bar Baz Qwe Asd Zxc Rty)
  create_descendants = Proc.new do |base|
    Bar = Class.new(base)
      Qwe = Class.new(Bar)
      Asd = Class.new(Bar)

    Baz = Class.new(base)
      Zxc = Class.new(Baz)
      Rty = Class.new(Baz)
  end

  build_tree = proc do
    Foo = Class.new
    Foo.send(:extend, ActiveSupport::DescendantsTracker)
    create_descendants.(Foo)
    ItIs::ClassTree.new([Foo] + Foo.descendants)
  end

  after(:each) do
    constants.each {|const| Object.send(:remove_const, const)}
  end

  it 'navigates on tree' do
    tree = build_tree.()

    bar_node = tree.nodes.find {|node| node.value == Bar}
    expect(bar_node.parent.value).to eq Foo

    expect(bar_node.children.map(&:value).to_set).to eq [Qwe, Asd].to_set
    expect(bar_node.parents.map(&:value)).to eq [Foo]

    qwe_node = tree.nodes.find {|node| node.value == Qwe}
    expect(qwe_node.parents.map(&:value)).to eq [Bar, Foo]
  end

  it 'traverse classes tree by levels' do
    tree = build_tree.()

    levels = []
    nodes = []
    tree.each_level do |level, level_nodes|
      levels << level
      nodes << level_nodes
    end

    expect(levels).to eq [0, 1, 2]
    expect(nodes[0].size).to eq 1
    expect(nodes[0].to_a[0].root?).to be true
    expect(nodes[0].to_a[0].value).to eq Foo

    expect(nodes[1].size).to eq 2
    nodes[1].each {|node| expect(node.root?).to be false}
    expect(nodes[1].map(&:value).to_set).to eq [Bar, Baz].to_set

    expect(nodes[2].size).to eq 4
    nodes[2].each {|node| expect(node.root?).to be false}
    expect(nodes[2].map(&:value).to_set).to eq [Qwe, Asd, Zxc, Rty].to_set
  end
end
