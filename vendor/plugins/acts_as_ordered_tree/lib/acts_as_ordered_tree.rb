# Acts As Ordered Tree v.1.2
# Copyright (c) 2006 Brian D. Burns <wizard.rb@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module WizardActsAsOrderedTree #:nodoc:
  module Acts #:nodoc:
    module OrderedTree #:nodoc:
      def self.included(base)
        base.extend AddActsAsMethod
      end

      module AddActsAsMethod
        # Configuration:
        #
        #   class Person < ActiveRecord::Base
        #     acts_as_ordered_tree :foreign_key   => :parent_id,
        #                          :order         => :position
        #   end
        #
        #   class CreatePeople < ActiveRecord::Migration
        #     def self.up
        #       create_table :people do |t|
        #         t.column :parent_id ,:integer ,:null => false ,:default => 0
        #         t.column :position  ,:integer
        #       end
        #       add_index(:people, :parent_id)
        #     end
        #   end
        #
        #
        def acts_as_ordered_tree(options = {})
          configuration = { :foreign_key   => :parent_id ,
                            :order         => :position  }
          configuration.update(options) if options.is_a?(Hash)

          belongs_to :parent_node,
                     :class_name    => name,
                     :foreign_key   => configuration[:foreign_key]

          has_many   :child_nodes,
                     :class_name    => name,
                     :foreign_key   => configuration[:foreign_key],
                     :order         => configuration[:order]

          cattr_reader :roots

          class_eval <<-EOV
            include WizardActsAsOrderedTree::Acts::OrderedTree::InstanceMethods

            def foreign_key_column
              :'#{configuration[:foreign_key]}'
            end

            def order_column
              :'#{configuration[:order]}'
            end

            def self.roots(reload = false)
              reload = true if !@@roots
              reload ? find(:all, :conditions => "#{configuration[:foreign_key]} = 0", :order => "#{configuration[:order]}") : @@roots
            end

            before_create  :add_to_list
            before_update  :check_list_changes
            after_update   :reorder_old_list
            before_destroy :destroy_descendants
            after_destroy  :reorder_old_list
          EOV
        end #acts_as_ordered_tree
      end #module AddActsAsMethod

      module InstanceMethods
        ## Tree Read Methods

        # returns an ordered array of all nodes without a parent
        #   i.e. parent_id = 0
        #
        #   return is cached
        #   use self.class.roots(true) to force a reload
        def self.roots(reload = false)
          # stub for rdoc - overwritten in AddActsAsMethod::acts_as_ordered_tree
        end

        # returns the top node in the object's tree
        #
        #   return is cached, unless nil
        #   use root(true) to force a reload
        def root(reload = false)
          reload = true if !@root
          reload ? find_root : @root
        end

        # returns an array of ancestors, starting from parent until root.
        #   return is cached
        #   use ancestors(true) to force a reload
        def ancestors(reload = false)
          reload = true if !@ancestors
          reload ? find_ancestors : @ancestors
        end

        # returns object's parent in the tree
        #   auto-loads itself on first access
        #   instead of returning "<parent_node not loaded yet>"
        #
        #   return is cached, unless nil
        #   use parent(true) to force a reload
        def parent(reload=false)
          reload = true if !@parent
          reload ? parent_node(true) : @parent
        end

        # returns an array of the object's immediate children
        #   auto-loads itself on first access
        #   instead of returning "<child_nodes not loaded yet>"
        #
        #   return is cached
        #   use children(true) to force a reload
        def children(reload=false)
          reload = true if !@children
          reload ? child_nodes(true) : @children
        end

        # returns an array of the object's descendants
        #
        #   return is cached
        #   use descendants(true) to force a reload
        def descendants(reload = false)
          @descendants = nil if reload
          reload = true if !@descendants
          reload ? find_descendants(self) : @descendants
        end

        ## List Read Methods

        # returns an array of the object's siblings, including itself
        #
        #   return is cached
        #   use self_and_siblings(true) to force a reload
        def self_and_siblings(reload = false)
          parent(reload) ? parent.children(reload) : self.class.roots(reload)
        end

        # returns an array of the object's siblings, excluding itself
        #
        #   return is cached
        #   use siblings(true) to force a reload
        def siblings(reload = false)
          self_and_siblings(reload) - [self]
        end

        # returns object's position in the list
        #   the list will either be parent.children,
        #   or self.class.roots
        #
        #   i.e. self.position
        def position_in_list
          self[order_column]
        end

        ## Tree Update Methods

        # shifts a node to another parent, optionally specifying it's position
        #   (descendants will follow along)
        #
        #   shift_to()
        #     defaults to the bottom of the "roots" list
        #
        #   shift_to(nil, new_sibling)
        #     will move the item to "roots",
        #     and position the item above new_sibling
        #
        #   shift_to(new_parent)
        #     will move the item to the new parent,
        #     and position at the bottom of the parent's list
        #
        #   shift_to(new_parent, new_sibling)
        #     will move the item to the new parent,
        #     and position the item above new_sibling
        #
        def shift_to(new_parent = nil, new_sibling = nil)
          if new_parent
            ok = new_parent.children(true) << self
          else
            ok = orphan
          end
          if ok && new_sibling
            ok = move_above(new_sibling) if self_and_siblings(true).include?(new_sibling)
          end
          return ok
        end

        # orphans the node (sends it to the roots list)
        #   (descendants follow)
        def orphan
          self[foreign_key_column] = 0
          self.update
        end

        # orphans the node's children
        #   sends all immediate children to the 'roots' list
        def orphan_children
          self.class.transaction do
            children(true).each{|child| child.orphan}
          end
        end

        # hands children off to parent
        #   if no parent, children will be orphaned
        def parent_adopts_children
          if parent(true)
            self.class.transaction do
              children(true).each{|child| parent.children << child}
            end
          else
            orphan_children
          end
        end

        # sends self and immediate children to the roots list
        def orphan_self_and_children
          self.class.transaction do
            orphan_children
            orphan
          end
        end

        # hands children off to parent (if possible), then orphans itself
        def orphan_self_and_parent_adopts_children
          self.class.transaction do
            parent_adopts_children
            orphan
          end
        end

        ## List Update Methods

        # moves the item above sibling in the list
        #   defaults to the top of the list
        def move_above(sibling = nil)
          if sibling
            return if (!self_and_siblings(true).include?(sibling) || (sibling == self))
            if sibling.position_in_list > position_in_list
              move_to(sibling.position_in_list - 1)
            else
              move_to(sibling.position_in_list)
            end
          else
            move_to_top
          end
        end

        # move to the top of the list
        def move_to_top
          return if position_in_list == 1
          move_to(1)
        end

        # swap with the node above self
        def move_higher
          return if position_in_list == 1
          move_to(position_in_list - 1)
        end

        # swap with the node below self
        def move_lower
          return if self == self_and_siblings(true).last
          move_to(position_in_list + 1)
        end

        # move to the bottom of the list
        def move_to_bottom
          return if self == self_and_siblings(true).last
          move_to(self_and_siblings.last.position_in_list)
        end

        ## Destroy Methods

        # sends immediate children to the 'roots' list, then destroy's self
        def destroy_and_orphan_children
          self.class.transaction do
            orphan_children
            self.destroy
          end
        end

        # hands immediate children of to it's parent, then destroy's self
        def destroy_and_parent_adopts_children
          self.class.transaction do
            parent_adopts_children
            self.destroy
          end
        end

        private
          def find_root
            node = self
            node = node.parent while node.parent(true)
            node
          end

          def find_ancestors
            node, nodes = self, []
            nodes << node = node.parent while node.parent(true)
            nodes
          end

          # recursive method
          def find_descendants(node)
            @descendants ||= []
            node.children(true).each do |child|
              @descendants << child
              find_descendants(child)
            end
            @descendants
          end

          def add_to_list
            new_position = position_in_list if (1..self_and_siblings(true).size).include?(position_in_list.to_i)
            add_to_list_bottom
            move_to(new_position, true) if new_position
          end

          def add_to_list_bottom
            self[order_column] = self_and_siblings.size + 1
          end

          def move_to(new_position, on_create = false)
            if parent(true)
              scope = "#{foreign_key_column} = #{parent.id}"
            else
              scope = "#{foreign_key_column} = 0"
            end
            if new_position < position_in_list
              # moving from lower to higher, increment all in between
              # #{order_column} >= #{new_position} AND #{order_column} < #{position_in_list}
              self.class.transaction do
                self.class.update_all(
                  "#{order_column} = (#{order_column} + 1)", "#{scope} AND (#{order_column} BETWEEN #{new_position} AND #{position_in_list - 1})"
                )
                if on_create
                  self[order_column] = new_position
                else
                  update_attribute(order_column, new_position)
                end
              end
            else
              # moving from higher to lower, decrement all in between
              # #{order_column} > #{position_in_list} AND #{order_column} <= #{new_position}
              self.class.transaction do
                self.class.update_all(
                  "#{order_column} = (#{order_column} - 1)", "#{scope} AND (#{order_column} BETWEEN #{position_in_list + 1} AND #{new_position})"
                )
                update_attribute(order_column, new_position)
              end
            end
          end

          def reorder_children
            self.class.transaction do
              children(true).each do |child|
                new_position = children.index(child) + 1
                child.update_attribute(order_column, new_position) if (child.position_in_list != new_position)
              end
            end
          end

          def reorder_roots
            self.class.transaction do
              self.class.roots(true).each do |root|
                new_position = self.class.roots.index(root) + 1
                root.update_attribute(order_column, new_position) if (root.position_in_list != new_position)
              end
            end
          end

          protected
            def destroy_descendants #:nodoc:
              # before_destroy callback (recursive)
              @old_parent = self.class.find(self).parent || 'root'
              self.children(true).each{|child| child.destroy}
            end

            def check_list_changes #:nodoc:
              # before_update callback
              #
              # Note: to shift to another parent AND specify a position, use shift_to()
              # i.e. don't assign the object a new position, then new_parent << obj
              # this will end up at the bottom of the list.
              #
              if !self_and_siblings(true).include?(self)
                add_to_list_bottom
                @old_parent = self.class.find(self).parent || 'root'
              end
            end

            def validate_on_update #:nodoc:
              if !self_and_siblings(true).include?(self)
                if self.parent == self
                  errors.add_to_base("cannot be a parent to itself.")
                elsif (self.parent && self.descendants(true).include?(self.parent))
                  errors.add_to_base("is an ancestor of the new parent.")
                end
              end
            end

            def reorder_old_list #:nodoc:
              # after_update and after_destroy callback
              # re-order the old parent's list
              if @old_parent == 'root'
                reorder_roots
              elsif @old_parent
                @old_parent.reorder_children
              end
            end

          #protected
        #private
      end #module InstanceMethods
    end #module OrderedTree
  end #module Acts
end #module WizardActsAsOrderedTree
