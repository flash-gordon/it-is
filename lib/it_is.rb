require 'active_support/concern'
require 'active_support/descendants_tracker'
require 'active_support/core_ext/string/inflections'
require 'it_is/class_tree'

module ItIs
  module DSL
    extend ActiveSupport::Concern

    module ClassMethods
      def it_will_be(name, root)
        ensure_has_descendants_tracker(root)
        root_name = :"@__#{name}_root__"
        instance_variable_set(root_name, root)

        base = self
        singleton_class.send(:define_method, :"#{name}_register") {base}

        instance_eval <<-EVAL, __FILE__, __LINE__ + 1
          @@__it_is_#{name}_relations__ = Hash.new do |hash, klass|
            hash[klass] ||= {}
          end

          def it_is_#{name}_for(*class_names)
            reset_#{name}_relations_cache
            @@__it_is_#{name}_relations__[self] = class_names
          end

          def #{name}_for(klass)
            #{name}_relations_cache[klass]
          end

          def #{name}_relations_cache
            raise ArgumentError unless self == #{name}_register
            @@__#{name}_relations_cache__ ||= resolve_relations(@@__it_is_#{name}_relations__, #{root_name})
          end

          def reset_#{name}_relations_cache
            @@__#{name}_relations_cache__ = nil
          end
        EVAL
      end

      def resolve_relations(mapping, root)
        reversed_mapping = build_reversed_mapping(mapping)
        tree = ClassTree.new([root] + root.descendants)
        cache = {}
        tree.each_level do |_, nodes|
          nodes.each do |node|
            classes = node.parents.map {|p| p.value}
            classes.unshift(node.value)
            cache[node.value] = classes.inject(nil) {|res, klass| res || reversed_mapping[klass]}
          end
        end
        cache
      end

    private

      def ensure_has_descendants_tracker(klass)
        raise ArgumentError, <<-MSG.strip unless klass.singleton_class < ActiveSupport::DescendantsTracker
          You must extend your base class with ActiveSupport::DescendantsTracker module. ItIs use last for tracking subclasses.
        MSG
      end

      def build_reversed_mapping(mapping)
        mapping.map.with_object({}) do |(mapped, class_names), reversed|
          class_names.map {|n| n.constantize}.each do |class_object|
            raise StandardError if reversed.has_key?(class_object)
            reversed[class_object] = mapped
          end
        end
      end

    end # ClassMethods
  end #DSL
end # ItIs