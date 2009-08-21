require File.dirname(__FILE__) + '/abstract_unit'
class ActsAsOrderedTreeTest < Test::Unit::TestCase

  def setup
    reload_test_tree
  end

  def test_validation
    people = Person.find(:all)
    # people[0] is gaining a new parent
    assert !(people[4].children << people[0]),"
      Validation failed:
      If you are using the 'validate_on_update' callback, make sure you use 'super'\n"
    assert_equal "is an ancestor of the new parent.", people[0].errors[:base]

    # people[2] is changing parents
    assert !(people[7].children << people[2])
    assert_equal "is an ancestor of the new parent.", people[0].errors[:base]

    assert !(people[3].children << people[3])
    assert_equal "cannot be a parent to itself.", people[3].errors[:base]

    # remember that the failed operations leave you with tainted objects
    assert people[2].parent == people[7]
    people[2].reload
    people[0].reload
    assert people[2].parent != people[7]
  end

  def test_validate_on_update_reloads_descendants
    people = Person.find(:all)
    # caching (descendants must be reloaded in validate_on_update)
    people[2].descendants # load descendants
    assert people[5].children << people[7]
    assert people[5].children.include?(people[7])
    # since people[2].descendants has already been loaded above,
    # it still includes people[7] as a descendant
    assert people[2].descendants.include?(people[7])
    # so, without the reload on people[2].descendants in validate_on_update,
    # the following would fail
    assert people[7].children << people[2], 'Validation Failed: descendants must be reloaded in validate_on_update'
  end

  def test_descendants
    roots = Person.roots
    assert !roots.empty?
    count = 0
    roots.each{|root| count = count + root.descendants.size + 1}
    assert count == Person.find(:all).size
  end

  def test_destroy_descendants
    people = Person.find(:all)
    assert_equal 7, people[2].descendants.size + 1
    assert people[2].destroy
    assert_equal (people.size - 7), Person.find(:all).size
  end

  def test_ancestors_and_roots
    people = Person.find(:all)
    assert people[7].ancestors == [people[4],people[2],people[0]]
    assert people[7].root == people[0]
    assert people[7].class.roots == [people[0],people[11]]
  end

  def test_destroy_and_reorder_list
    people = Person.find(:all)
    assert_equal [people[1],people[2],people[3],people[4],people[7],people[8],people[9],people[10],people[5],people[6]], people[0].descendants
    assert_equal [people[1],people[2],people[5],people[6]], people[5].self_and_siblings
    assert_equal 3, people[5].position_in_list
    # taint people[2].parent (since the plugin protects against this)
    people[10].children << people[2]
    assert_equal people[10], people[2].parent
    assert people[2].destroy
    assert_equal (people.size - 7), Person.find(:all).size
    # Note that I don't need to reload self_and_siblings or children in this case,
    # since the re-ordering action is actually happening against people[0].children
    # (which is what self_and_syblings returns)
    assert_equal people[5].self_and_siblings, people[0].children
    assert_equal [people[1],people[5],people[6]], people[5].self_and_siblings
    people[5].reload
    assert_equal 2, people[5].position_in_list
    # of course, descendants must always be reloaded
    assert people[0].descendants.include?(people[7])
    assert !people[0].descendants(true).include?(people[7])
  end

  def test_reorder_lists
    people = Person.find(:all)
    # re-order children
    assert people[13].children << people[4]
    assert_equal 5, people[4].position_in_list
    people[9].reload
    assert_equal 2, people[9].position_in_list
    # re-order roots
    assert people[13].children << people[0]
    assert_equal 6, people[0].position_in_list
    people[11].reload
    assert_equal 1, people[11].position_in_list
  end

  def test_move_higher
    people = Person.find(:all)
    assert people[9].move_higher
    assert_equal 2, people[9].position_in_list
    people[4].reload
    assert_equal 3, people[4].position_in_list
  end

  def test_move_lower
    people = Person.find(:all)
    assert people[4].move_lower
    assert_equal 3, people[4].position_in_list
    people[9].reload
    assert_equal 2, people[9].position_in_list
  end

  def test_move_to_top
    people = Person.find(:all)
    assert people[4].move_to_top
    people = Person.find(:all)
    assert_equal 1, people[4].position_in_list
    assert_equal 2 ,people[3].position_in_list
    assert_equal 3 ,people[9].position_in_list
    assert_equal 4, people[10].position_in_list
  end

  def test_move_to_bottom
    people = Person.find(:all)
    assert people[4].move_to_bottom
    people = Person.find(:all)
    assert_equal 1, people[3].position_in_list
    assert_equal 2 ,people[9].position_in_list
    assert_equal 3 ,people[10].position_in_list
    assert_equal 4, people[4].position_in_list
  end

  def test_move_above_moving_higher
    people = Person.find(:all)
    assert people[10].move_above(people[4])
    people = Person.find(:all)
    assert_equal [people[3],people[10],people[4],people[9]], people[2].children
    assert_equal 1, people[3].position_in_list
    assert_equal 2 ,people[10].position_in_list
    assert_equal 3 ,people[4].position_in_list
    assert_equal 4, people[9].position_in_list
  end

  def test_move_above_moving_lower
    people = Person.find(:all)
    assert people[3].move_above(people[10])
    people = Person.find(:all)
    assert_equal [people[4],people[9],people[3],people[10]], people[2].children
    assert_equal 1, people[4].position_in_list
    assert_equal 2 ,people[9].position_in_list
    assert_equal 3 ,people[3].position_in_list
    assert_equal 4, people[10].position_in_list
  end

  def test_shift_to_with_position
    people = Person.find(:all)
    assert people[4].shift_to(people[13], people[20])
    people = Person.find(:all)
    assert_equal [people[3],people[9],people[10]], people[2].children
    assert_equal 1, people[3].position_in_list
    assert_equal 2 ,people[9].position_in_list
    assert_equal 3 ,people[10].position_in_list
    assert_equal [people[14],people[15],people[4],people[20],people[21]], people[13].children
    assert_equal 1, people[14].position_in_list
    assert_equal 2 ,people[15].position_in_list
    assert_equal 3 ,people[4].position_in_list
    assert_equal 4, people[20].position_in_list
    assert_equal 5, people[21].position_in_list
  end

  def test_shift_to_without_position
    people = Person.find(:all)
    assert people[4].shift_to(people[13])
    people = Person.find(:all)
    assert_equal [people[3],people[9],people[10]], people[2].children
    assert_equal 1, people[3].position_in_list
    assert_equal 2 ,people[9].position_in_list
    assert_equal 3 ,people[10].position_in_list
    assert_equal [people[14],people[15],people[20],people[21],people[4]], people[13].children
    assert_equal 1, people[14].position_in_list
    assert_equal 2 ,people[15].position_in_list
    assert_equal 3 ,people[20].position_in_list
    assert_equal 4, people[21].position_in_list
    assert_equal 5, people[4].position_in_list
  end

  def test_shift_to_roots_without_position__ie__orphan
    people = Person.find(:all)
    assert people[4].orphan
    people = Person.find(:all)
    assert_equal [people[3],people[9],people[10]], people[2].children
    assert_equal 1, people[3].position_in_list
    assert_equal 2 ,people[9].position_in_list
    assert_equal 3 ,people[10].position_in_list
    assert_equal [people[0],people[11],people[4]], Person.roots
    assert_equal 1, people[0].position_in_list
    assert_equal 2 ,people[11].position_in_list
    assert_equal 3 ,people[4].position_in_list
  end

  def test_shift_to_roots_with_position
    people = Person.find(:all)
    assert people[4].shift_to(nil, people[11])
    people = Person.find(:all)
    assert_equal [people[3],people[9],people[10]], people[2].children
    assert_equal 1, people[3].position_in_list
    assert_equal 2 ,people[9].position_in_list
    assert_equal 3 ,people[10].position_in_list
    assert_equal [people[0],people[4],people[11]], Person.roots
    assert_equal 1, people[0].position_in_list
    assert_equal 2 ,people[4].position_in_list
    assert_equal 3 ,people[11].position_in_list
  end

  def test_orphan_children
    people = Person.find(:all)
    assert people[2].orphan_children
    people = Person.find(:all)
    assert people[2].children.empty?
    assert_equal [people[0],people[11],people[3],people[4],people[9],people[10]], Person.roots
  end

  def test_parent_adopts_children
    people = Person.find(:all)
    assert people[4].parent_adopts_children
    people = Person.find(:all)
    assert people[4].children.empty?
    assert_equal [people[3],people[4],people[9],people[10],people[7],people[8]], people[2].children
  end

  def test_orphan_self_and_children
    people = Person.find(:all)
    assert people[2].orphan_self_and_children
    people = Person.find(:all)
    assert people[2].children.empty?
    assert_equal [people[0],people[11],people[3],people[4],people[9],people[10],people[2]], Person.roots
  end

  def test_orphan_self_and_parent_adopts_children
    people = Person.find(:all)
    assert people[4].orphan_self_and_parent_adopts_children
    people = Person.find(:all)
    assert people[4].children.empty?
    assert_equal [people[3],people[9],people[10],people[7],people[8]], people[2].children
    assert_equal 1, people[3].position_in_list
    assert_equal 2 ,people[9].position_in_list
    assert_equal 3 ,people[10].position_in_list
    assert_equal 4, people[7].position_in_list
    assert_equal 5, people[8].position_in_list
    assert_equal [people[0],people[11],people[4]], Person.roots
  end

  def test_destroy_and_orphan_children
    people = Person.find(:all)
    assert people[2].destroy_and_orphan_children
    people = Person.find(:all)
    # remember, since we deleted people[2], all below get shifted up
    assert_equal [people[0],people[10],people[2],people[3],people[8],people[9]], Person.roots
    assert_equal [people[1],people[4],people[5]], people[0].children
    assert_equal 1, people[1].position_in_list
    assert_equal 2 ,people[4].position_in_list
    assert_equal 3 ,people[5].position_in_list
  end

  def test_destroy_and_parent_adopts_children
    people = Person.find(:all)
    assert people[4].destroy_and_parent_adopts_children
    people = Person.find(:all)
    # remember, since we deleted people[4], all below get shifted up
    assert_equal [people[3],people[8],people[9],people[6],people[7]], people[2].children
    assert_equal 1, people[3].position_in_list
    assert_equal 2 ,people[8].position_in_list
    assert_equal 3 ,people[9].position_in_list
    assert_equal 4, people[6].position_in_list
    assert_equal 5, people[7].position_in_list
  end

  def test_create_with_position_method_1
    people = Person.find(:all)
    # method 1
    assert people[2].children << Person.new(:position => 3, :name => 'Person_23')
    people = Person.find(:all)
    assert_equal [people[3],people[4],people[22],people[9],people[10]], people[2].children
    assert_equal 1, people[3].position_in_list
    assert_equal 2 ,people[4].position_in_list
    assert_equal 3 ,people[22].position_in_list
    assert_equal 4, people[9].position_in_list
    assert_equal 5, people[10].position_in_list
  end

  def test_create_with_position_method_2
    people = Person.find(:all)
    # method 2
    assert Person.create(:parent_id => people[2].id, :position => 2, :name => 'Person_23')
    people = Person.find(:all)
    assert_equal [people[3],people[22],people[4],people[9],people[10]], people[2].children
    assert_equal 1, people[3].position_in_list
    assert_equal 2 ,people[22].position_in_list
    assert_equal 3 ,people[4].position_in_list
    assert_equal 4, people[9].position_in_list
    assert_equal 5, people[10].position_in_list
  end

  def test_create_with_position_method_3
    people = Person.find(:all)
    # method 3
    assert people[2].children.create(:position => 4, :name => 'Person_23')
    people = Person.find(:all)
    assert_equal [people[3],people[4],people[9],people[22],people[10]], people[2].children
    assert_equal 1, people[3].position_in_list
    assert_equal 2 ,people[4].position_in_list
    assert_equal 3, people[9].position_in_list
    assert_equal 4 ,people[22].position_in_list
    assert_equal 5, people[10].position_in_list
  end

  def test_create_with_position_method_4
    people = Person.find(:all)
    # method 4 (new 'root')
    assert Person.create(:position => 2, :name => 'Person_23')
    people = Person.find(:all)
    assert_equal [people[0],people[22],people[11]], Person.roots
    assert_equal 1, people[0].position_in_list
    assert_equal 2 ,people[22].position_in_list
    assert_equal 3 ,people[11].position_in_list
  end

  def test_create_with_invalid_position
    # invalid positions go to bottom of the list
    people = Person.find(:all)
    person_23 = people[2].children.create(:position => 15, :name => 'Person_23')
    assert_equal 5, person_23.position_in_list
  end

  private
    # Test Tree
    #
    # people[0]
    #   \_ people[1]
    #   \_ people[2]
    #   |    \_ people[3]
    #   |    \_ people[4]
    #   |    |   \_ people[7]
    #   |    |   \_ people[8]
    #   |    \_ people[9]
    #   |    \_ people[10]
    #   \_ people[5]
    #   \_ people[6]
    #   |
    #   |
    # people[11]
    #   \_ people[12]
    #   \_ people[13]
    #   |    \_ people[14]
    #   |    \_ people[15]
    #   |    |   \_ people[18]
    #   |    |   \_ people[19]
    #   |    \_ people[20]
    #   |    \_ people[21]
    #   \_ people[16]
    #   \_ people[17]
    #
    #
    #  +----+-----------+----------+-----------+
    #  | id | parent_id | position | name      |
    #  +----+-----------+----------+-----------+
    #  |  1 |         0 |        1 | Person_1  |
    #  |  2 |         1 |        1 | Person_2  |
    #  |  3 |         1 |        2 | Person_3  |
    #  |  4 |         3 |        1 | Person_4  |
    #  |  5 |         3 |        2 | Person_5  |
    #  |  6 |         1 |        3 | Person_6  |
    #  |  7 |         1 |        4 | Person_7  |
    #  |  8 |         5 |        1 | Person_8  |
    #  |  9 |         5 |        2 | Person_9  |
    #  | 10 |         3 |        3 | Person_10 |
    #  | 11 |         3 |        4 | Person_11 |
    #  | 12 |         0 |        2 | Person_12 |
    #  | 13 |        12 |        1 | Person_13 |
    #  | 14 |        12 |        2 | Person_14 |
    #  | 15 |        14 |        1 | Person_15 |
    #  | 16 |        14 |        2 | Person_16 |
    #  | 17 |        12 |        3 | Person_17 |
    #  | 18 |        12 |        4 | Person_18 |
    #  | 19 |        16 |        1 | Person_19 |
    #  | 20 |        16 |        2 | Person_20 |
    #  | 21 |        14 |        3 | Person_21 |
    #  | 22 |        14 |        4 | Person_22 |
    #  +----+-----------+----------+-----------+
    #
    def reload_test_tree
      Person.delete_all
      people = []
      i = 1
      people << Person.create(:name => "Person_#{i}")
      [0,2,0,4,2,-1,11,13,11,15,13].each do |n|
        if n == -1
          i = i.next
          people << Person.create(:name => "Person_#{i}")
        else
          2.times do
            i = i.next
            people << people[n].children.create(:name => "Person_#{i}")
          end
        end
      end
    end
end
