require 'set'

module ItIs
  class ClassTree
    # Trivial work with classes tree
    #                   Foo
    #                    ^
    #                    |
    #          Bar ------+------ Baz
    #           ^                 ^
    #           |                 |
    #           |                 |
    #    Qwe ---+--- Asd   Zxc ---+--- Rty
    #
    # tree = ItIs::ClassTree.new([Foo, Bar, Baz, Qwe, Asd, Zxc, Rty].shuffle)
    # tree.each_level do |level, nodes|
    #   puts '%s -> %s' [level, nodes.inspect]
    # end
    # # 0 -> [ItIs::ClassTree::Root(Foo)]
    # # 1 -> [ItIs::ClassTree::Node(Bar), ItIs::ClassTree::Node(Baz)]
    # # 2 -> [ItIs::ClassTree::Node(Qwe), ItIs::ClassTree::Node(Asd), ItIs::ClassTree::Node(Zxc), ItIs::ClassTree::Node(Rty)]

    class Node
      attr_reader :value
      attr_accessor :parent, :children

      def initialize(value, children = [])
        @value = value
        @children = children
        children.each {|cn| cn.parent = self}
      end

      def root?
        false
      end

      def all_children
        (children + children.map {|child| child.all_children}).flatten
      end

      def parents
        [parent] + parent.parents
      end
    end

    class Root < Node
      def root?
        true
      end

      def parents
        []
      end
    end

    attr_reader :nodes

    def initialize(classes_list)
      builder = proc do |klass|
        children = classes_list.select {|c| c.superclass == klass}
        Node.new(klass, children.map(&builder))
      end
      root_node = builder.(classes_list.sort_by {|c| c.ancestors.size}.first)
      @nodes = [root_node] + root_node.all_children
      set_root
    end

    def each_level
      level = 0
      level_nodes = [root].to_set

      loop do
        yield(level, level_nodes)
        level += 1
        level_nodes = level_nodes.map {|ln| ln.children}.flatten.to_set
        break if level_nodes.empty?
      end
    end

    def root
      nodes.find {|node| node.root?}
    end

  protected

    def set_root
      root = nodes.find {|node| node.parent.nil?}
      nodes.delete(root)
      nodes << Root.new(root.value, root.children)
    end
  end
end