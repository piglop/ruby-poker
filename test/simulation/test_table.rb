require 'test_helper'
require 'ruby-poker/simulation'

class TestTable < Test::Unit::TestCase
  include RubyPoker::Simulation
  
  context "Basic stuff" do
    setup do
      @table = Table.new
    end

    should "a table should have 10 seats by default" do
      assert_equal(@table.seats.length, 10)
    end

    should "all seats at a new table should be empty" do
      @table.seats.each { |seat|
        assert_equal(seat.player, nil)
      }
    end

    should "players should be able to sit down" do
      player = Player.new(5000)
      @table.sit(player, 4, 1000)
    end

    should "players shouldn't be able to sit down in an occupied seat" do
      player1 = Player.new(5000)
      @table.sit(player1, 4, 1000)

      player2 = Player.new(5000)
      @table.sit(player2, 4, 1000)

      assert_equal(@table.seats[4].player, player1)
    end
  end

  context "Order stuff" do
    setup do
      @table = Table.new
      @table.sit(Player.new(5000), 1, 1000)
      @table.sit(Player.new(5000), 3, 1000)
      @table.sit(Player.new(5000), 5, 1000)
      @table.sit(Player.new(5000), 7, 1000)
      @table.sit(Player.new(5000), 9, 1000)
    end

    should "get correct button position" do
      assert_equal(1, @table.button)
    end

    should "get player in sb" do
      assert_equal(3, @table.sb)
    end

    should "get player in bb" do
      assert_equal(5, @table.bb)
    end

    should "get utg player" do
      assert_equal(7, @table.utg)
    end

    should "get correct deal order preflop" do
      assert_equal([7, 9, 1, 3, 5], @table.action_order_preflop)
    end

    should "get correct action order postflop" do
      assert_equal([3, 5, 7, 9, 1], @table.action_order_postflop)
    end
  end

  context "Deal stuff" do
    setup do
      @table = Table.new(10, 1)
      @table.sit(Player.new(5000), 1, 1000)
      @table.sit(Player.new(5000), 3, 1000)
      @table.sit(Player.new(5000), 5, 1000)
      @table.sit(Player.new(5000), 7, 1000)
      @table.sit(Player.new(5000), 9, 1000)
    end

    should "deal 2 hole cards to each player" do
      @table.deal_holes
      @table.seats.each { |seat|
        if seat.player
          assert_equal(2, seat.hand.to_a.length)
        end
      }
    end

    should "deal flop" do
      @table.deal_holes
      @table.deal_flop
      assert_equal(3, @table.community.to_a.length)
    end

    should "deal turn" do
      @table.deal_holes
      @table.deal_flop
      @table.deal_turn
      assert_equal(4, @table.community.to_a.length)
    end

    should "deal river" do
      @table.deal_holes
      @table.deal_flop
      @table.deal_turn
      @table.deal_river
      assert_equal(5, @table.community.to_a.length)
    end

    should "determine winners" do
      @table.deal_holes
      @table.deal_flop
      @table.deal_turn
      @table.deal_river
      winners, best_hand = @table.winners
      assert_equal([1], winners)
    end

    should "determine winner (running whole hand)" do
      winners, best_hand = @table.run_hand
      assert_equal([1], winners)
    end
  end

  context "Outcomes" do
    should "Handle full houses correctly" do
      table = Table.new(10, 59)
      # T's full of A's
      table.sit(Player.new(5000), 1, 1000)
      table.sit(Player.new(5000), 3, 1000)
      table.sit(Player.new(5000), 5, 1000)
      table.sit(Player.new(5000), 7, 1000)
      winner, best_hand, hands = table.run_hand
      assert_equal("Full house 2's full of A's", best_hand.rank_full)
    end

    should "Handle Ties" do
      table = Table.new(10, 75)
      # 7's full of 4's
      table.sit(Player.new(5000), 1, 1000)
      table.sit(Player.new(5000), 3, 1000)
      table.sit(Player.new(5000), 5, 1000)
      table.sit(Player.new(5000), 7, 1000)
      winners, best_hand = table.run_hand
      #table.dump_hands
      assert_equal(winners, [1,5])
    end

  end
  
  context "Blinds" do
    setup do
      @table = Table.new(10, 1)
      @table.sit(Player.new(5000), 1, 1000)
      @table.sit(Player.new(5000), 3, 1000)
      @table.sit(Player.new(5000), 5, 1000)
      @table.sit(Player.new(5000), 7, 1000)
      @table.sit(Player.new(5000), 9, 1000)
    end
    
    should "be collected" do
      @table.collect_blinds
      assert_equal 1000 - @table.small_blind, @table.seats[@table.sb].chips
      assert_equal 1000 - @table.big_blind, @table.seats[@table.bb].chips
    end
    
    should "not be collected on non blind players" do
      @table.collect_blinds
      @table.seats.each do |seat|
        if seat.player and seat != @table.seats[@table.sb] and seat != @table.seats[@table.bb]
          assert_equal 1000, seat.chips
        end
      end
    end
    
    should "be collected on each hand" do
      @table.expects(:collect_blinds).once.with()
      @table.run_hand
    end
  end
  
  context "Table preflop" do
    setup do
      @table = Table.new(10, 1)
      @table.sit(Player.new(5000), 1, 1000)
      @table.sit(Player.new(5000), 3, 1000)
      @table.sit(Player.new(5000), 5, 1000)
      @table.sit(Player.new(5000), 7, 1000)
      @table.sit(Player.new(5000), 9, 1000)
    end
    
    should "ask players to play" do
      betting_round = sequence('betting round')
      
      @table.action_order_preflop.each do |seat_index|
        if seat_index == @table.bb
          @table.seats[seat_index].player.expects(:play).never
        else
          @table.seats[seat_index].player.expects(:play).once.with(@table).returns(:fold).in_sequence(betting_round)
        end
      end
      winners, best_hand = @table.run_hand
      assert_equal nil, best_hand
      assert_equal [@table.seats[@table.bb].player], winners
    end
  end
end
