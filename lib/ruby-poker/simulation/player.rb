module RubyPoker::Simulation
  class Player
    attr_accessor :chips

    def initialize(chips)
      @chips = chips
    end
    
    def play(table)
      :call
    end
  end
end