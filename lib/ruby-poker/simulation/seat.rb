module RubyPoker::Simulation
  class Seat
    attr_accessor :player, :chips
    attr_reader :number
    attr_accessor :folded

    def initialize(opts = {})
      opts = {:chips => 0}.merge(opts)
      @number = opts[:number]
      @player = opts[:player]
      @chips = opts[:chips]
    end
  end
end