require 'ruby2d'

# Maze Escape Game
class MazeGame
  CELL_SIZE = 40
  PLAYER_COLOR = 'lime'
  WALL_COLOR = 'navy'
  PATH_COLOR = 'white'
  EXIT_COLOR = 'red'
  FOG_COLOR = Color.new([0, 0, 0, 0.7])
  VISIBILITY_RADIUS = 3

  def initialize(width: 10, height: 10)
    @width = width
    @height = height
    @maze = Maze.new(@width, @height)
    @player = Player.new(1, 1) # Start at top-left corner
    @exit_pos = [@width - 2, @height - 2] # Exit at bottom-right corner
    @moves = 0
    @game_over = false
    @fog_of_war = true
    
    setup_window
    generate_maze
    set_window_title
  end

  def setup_window
    window_width = @width * CELL_SIZE
    window_height = @height * CELL_SIZE
    set title: "Maze Escape", width: window_width, height: window_height
  end

  def generate_maze
    @maze.generate!(@player.x, @player.y)
  end

  def set_window_title
    set title: "Maze Escape - Moves: #{@moves}"
  end

  def start
    update do
      render
    end

    on :key_down do |event|
      handle_input(event.key) unless @game_over
    end

    show
  end

  def handle_input(key)
    case key
    when 'up', 'down', 'left', 'right'
      move_player(key)
    when 'r'
      restart_game
    when 'f'
      toggle_fog_of_war
    end
  end

  def move_player(direction)
    dx, dy = 0, 0
    case direction
    when 'up' then dy = -1
    when 'down' then dy = 1
    when 'left' then dx = -1
    when 'right' then dx = 1
    end

    new_x, new_y = @player.x + dx, @player.y + dy

    if @maze.valid_move?(new_x, new_y)
      @player.move(dx, dy)
      @moves += 1
      set_window_title
      check_win_condition
    end
  end

  def check_win_condition
    if @player.x == @exit_pos[0] && @player.y == @exit_pos[1]
      @game_over = true
      show_win_message
    end
  end

  def show_win_message
    Text.new(
      "You Escaped in #{@moves} moves!",
      x: CELL_SIZE, y: CELL_SIZE * (@height / 2),
      size: 20,
      color: 'green',
      z: 10
    )
    Text.new(
      "Press R to restart",
      x: CELL_SIZE, y: CELL_SIZE * (@height / 2) + 30,
      size: 20,
      color: 'green',
      z: 10
    )
  end

  def restart_game
    @maze = Maze.new(@width, @height)
    @player = Player.new(1, 1)
    @moves = 0
    @game_over = false
    generate_maze
    set_window_title
  end

  def toggle_fog_of_war
    @fog_of_war = !@fog_of_war
  end

  def render
    clear
    
    # Draw maze
    @height.times do |y|
      @width.times do |x|
        if @maze.wall?(x, y)
          draw_cell(x, y, WALL_COLOR)
        else
          draw_cell(x, y, PATH_COLOR)
        end
      end
    end
    
    # Draw exit
    draw_cell(@exit_pos[0], @exit_pos[1], EXIT_COLOR)
    
    # Draw player
    draw_cell(@player.x, @player.y, PLAYER_COLOR)
    
    # Apply fog of war
    apply_fog_of_war if @fog_of_war
  end

  def draw_cell(x, y, color)
    Square.new(
      x: x * CELL_SIZE, y: y * CELL_SIZE,
      size: CELL_SIZE,
      color: color
    )
  end

  def apply_fog_of_war
    @height.times do |y|
      @width.times do |x|
        distance = Math.sqrt((x - @player.x)**2 + (y - @player.y)**2)
        if distance > VISIBILITY_RADIUS
          Square.new(
            x: x * CELL_SIZE, y: y * CELL_SIZE,
            size: CELL_SIZE,
            color: FOG_COLOR
          )
        end
      end
    end
  end
end

# Player class
class Player
  attr_accessor :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def move(dx, dy)
    @x += dx
    @y += dy
  end
end

# Maze class using Recursive Backtracking algorithm
class Maze
  DIRECTIONS = [[1, 0], [-1, 0], [0, 1], [0, -1]]

  def initialize(width, height)
    @width = width
    @height = height
    @grid = Array.new(height) { Array.new(width, 1) } # 1 = wall, 0 = path
  end

  def wall?(x, y)
    @grid[y][x] == 1
  end

  def valid_move?(x, y)
    x.between?(0, @width - 1) && y.between?(0, @height - 1) && !wall?(x, y)
  end

  def generate!(start_x, start_y)
    carve_passage(start_x, start_y)
    # Ensure exit is reachable
    @grid[@height - 2][@width - 2] = 0
  end

  private

  def carve_passage(x, y)
    @grid[y][x] = 0 # Mark current cell as path
    
    directions = DIRECTIONS.shuffle
    directions.each do |dx, dy|
      nx, ny = x + dx * 2, y + dy * 2
      
      if ny.between?(0, @height - 1) && nx.between?(0, @width - 1) && @grid[ny][nx] == 1
        @grid[y + dy][x + dx] = 0 # Carve through the wall
        carve_passage(nx, ny)
      end
    end
  end
end

# Start the game
game = MazeGame.new(width: 15, height: 15)
game.start
