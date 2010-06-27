module RubyPoker::Simulation
  class Player
    attr_accessor :hand, :chips

    def initialize(chips)
      @hand = nil
      @chips = chips
    end
    
    def play(table)
      :call
    end
  end
end