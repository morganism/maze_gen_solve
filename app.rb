# maze_app.rb
require 'set'
require 'io/console' # For potential future enhancements, though not strictly needed for basic file I/O

class Maze
  attr_reader :width, :height, :grid, :grid_width, :grid_height, :start_pos, :end_pos

  # Directions: N, S, E, W (dy, dx)
  DIRECTIONS = {
    N: [-1, 0],
    S: [1, 0],
    E: [0, 1],
    W: [0, -1]
  }.freeze

  # Opposite directions for carving walls
  OPPOSITE = { N: :S, S: :N, E: :W, W: :E }.freeze

  # Characters for display and file format
  WALL = '#'
  PASSAGE = ' '
  START = 'S'
  END = 'E'
  PATH = '*'

  # Option 1: Initialize for Generation
  def initialize(width, height)
    # Ensure dimensions are positive
    raise ArgumentError, "Width must be positive" unless width > 0
    raise ArgumentError, "Height must be positive" unless height > 0

    @width = width # Logical width (number of cells)
    @height = height # Logical height (number of cells)

    # Grid size needs to account for walls between cells and boundary walls
    @grid_width = width * 2 + 1
    @grid_height = height * 2 + 1

    # Initialize grid full of walls
    @grid = Array.new(@grid_height) { Array.new(@grid_width, WALL) }

    @start_pos = nil
    @end_pos = nil
    @logical_start = nil
    @logical_end = nil
  end

  # Private constructor used by load_from_file
  private_class_method :new

  # Option 2: Factory method to load from file
  def self.load_from_file(filename)
    unless File.exist?(filename) && File.readable?(filename)
      raise IOError, "Cannot open file or file does not exist: #{filename}"
    end

    lines = File.readlines(filename).map(&:chomp)
    raise ArgumentError, "File cannot be empty: #{filename}" if lines.empty?

    grid_height = lines.size
    grid_width = lines[0].length
    grid = []
    start_pos = nil
    end_pos = nil

    lines.each_with_index do |line, r|
      raise ArgumentError, "Inconsistent row length in file" if line.length != grid_width
      row_chars = line.chars
      grid << row_chars
      # Find S and E while reading
      row_chars.each_with_index do |char, c|
        start_pos = [r, c] if char == START
        end_pos = [r, c] if char == END
      end
    end

    raise ArgumentError, "Start position 'S' not found in file: #{filename}" unless start_pos
    raise ArgumentError, "End position 'E' not found in file: #{filename}" unless end_pos

    # Create a new Maze object without calling the public initialize
    # We use allocate + manual instance variable setting.
    maze = allocate

    # Approximate logical dimensions based on grid size (assumes standard format)
    height = (grid_height - 1) / 2
    width = (grid_width - 1) / 2

    # Set instance variables directly
    maze.instance_variable_set(:@grid, grid)
    maze.instance_variable_set(:@width, width) # Approximated
    maze.instance_variable_set(:@height, height) # Approximated
    maze.instance_variable_set(:@grid_width, grid_width)
    maze.instance_variable_set(:@grid_height, grid_height)
    maze.instance_variable_set(:@start_pos, start_pos)
    maze.instance_variable_set(:@end_pos, end_pos)
    # Logical start/end aren't known from file, leave as nil or approximate
    maze.instance_variable_set(:@logical_start, nil)
    maze.instance_variable_set(:@logical_end, nil)

    maze # Return the loaded maze object
  end

  # --- Maze Generation (Recursive Backtracker) ---

  def generate(start_x = 0, start_y = 0)
    # Ensure start coordinates are within logical bounds
    start_x = 0 if start_x < 0 || start_x >= @width # Use instance vars now
    start_y = 0 if start_y < 0 || start_y >= @height

    # Set logical start/end cells (can be customized)
    @logical_start = [start_y, start_x]
    @logical_end = [height - 1, width - 1] # Often bottom-right

    # Start carving the maze recursively
    carve_passages_from(start_y, start_x)

    # Place Start and End markers in the grid
    @start_pos = logical_to_grid(@logical_start[0], @logical_start[1])
    @end_pos = logical_to_grid(@logical_end[0], @logical_end[1])
    @grid[@start_pos[0]][@start_pos[1]] = START

    # Ensure End position is a passage before placing E
    # (Recursive backtracker guarantees connectivity, so it should be)
    @grid[@end_pos[0]][@end_pos[1]] = END if @grid[@end_pos[0]][@end_pos[1]] == PASSAGE


    # If by chance End position was still a wall (unlikely with this algo),
    # we might need a fallback or error. For now, assume generation works.
    unless @grid[@end_pos[0]][@end_pos[1]] == END
       # This case is highly unlikely with recursive backtracker starting from 0,0
       # and ending at bottom-right if it carves correctly.
       # Find *any* passage cell near bottom right as a fallback if needed.
       puts "Warning: Could not place End marker at default position. Maze might be unusual."
       # As a simple fallback, just ensure the previously calculated @end_pos is marked
       @grid[@end_pos[0]][@end_pos[1]] = END # Force it, even if it overwrites a wall temporarily
    end


    self # Return the maze object
  end

  private

  def carve_passages_from(cy, cx)
    # Mark the current logical cell as visited by carving it in the grid
    grid_y, grid_x = logical_to_grid(cy, cx)
    # Ensure cell is within grid bounds before carving (should be, but safety check)
    if grid_y.between?(0, @grid_height - 1) && grid_x.between?(0, @grid_width - 1)
        @grid[grid_y][grid_x] = PASSAGE # Carve the cell itself
    else
        # This indicates an issue with logical_to_grid or initial parameters
        puts "Warning: Attempted to carve outside grid bounds at #{grid_y}, #{grid_x}"
        return
    end

    # Get neighbors in random order
    directions = DIRECTIONS.keys.shuffle

    directions.each do |direction|
      ny, nx = cy + DIRECTIONS[direction][0], cx + DIRECTIONS[direction][1]

      # Check if the neighbor is within logical bounds
      if ny.between?(0, @height - 1) && nx.between?(0, @width - 1)
        grid_ny, grid_nx = logical_to_grid(ny, nx)

        # Check grid bounds for neighbor cell access
        if grid_ny.between?(0, @grid_height - 1) && grid_nx.between?(0, @grid_width - 1)
            # Check if the neighbor cell hasn't been visited yet (is still a wall)
            if @grid[grid_ny][grid_nx] == WALL
              # Carve the wall between the current cell and the neighbor
              wall_y = grid_y + DIRECTIONS[direction][0]
              wall_x = grid_x + DIRECTIONS[direction][1]

              # Check grid bounds for wall access
               if wall_y.between?(0, @grid_height - 1) && wall_x.between?(0, @grid_width - 1)
                    @grid[wall_y][wall_x] = PASSAGE

                    # Recursively visit the neighbor
                    carve_passages_from(ny, nx)
               else
                    puts "Warning: Attempted to carve wall outside grid bounds at #{wall_y}, #{wall_x}"
               end
            end
        else
            puts "Warning: Neighbor grid coordinates #{grid_ny}, #{grid_nx} out of bounds."
        end
      end
    end
  end


  # Convert logical cell coordinates (0..width-1, 0..height-1) to grid coordinates
  def logical_to_grid(y, x)
    # Add boundary checks for safety, although inputs should be valid
    gy = y.clamp(0, @height - 1) * 2 + 1
    gx = x.clamp(0, @width - 1) * 2 + 1
    [gy, gx]
  end

  public # Make solve, save and display public again

  # --- Maze Saving ---
  def save_to_file(filename)
    raise StandardError, "Maze grid not available to save." unless @grid
    begin
      File.open(filename, 'w') do |file|
        @grid.each do |row|
          file.puts row.join('')
        end
      end
      puts "Maze successfully saved to #{filename}"
      true
    rescue IOError => e
      puts "Error saving maze to file #{filename}: #{e.message}"
      false
    end
  end

  # --- Maze Solving (Depth-First Search) ---

  def solve
    # Ensure start/end points exist (could be loaded or generated)
    unless @start_pos && @grid[@start_pos[0]][@start_pos[1]] == START
        raise StandardError, "Start position 'S' is missing or invalid in the maze grid."
    end
     unless @end_pos && @grid[@end_pos[0]][@end_pos[1]] == END
        raise StandardError, "End position 'E' is missing or invalid in the maze grid."
    end

    # Reset any previous path markers, keeping S and E
    @grid.each_with_index do |row, r|
      row.each_with_index do |cell, c|
        @grid[r][c] = PASSAGE if cell == PATH
      end
    end

    # Keep track of visited cells during the *solve* process
    visited = Set.new
    path_found = solve_recursive(@start_pos[0], @start_pos[1], visited)

    # Ensure Start marker is restored if overwritten by path marker logic
    @grid[@start_pos[0]][@start_pos[1]] = START # Force it back just in case

    return path_found
  end

  private

  def solve_recursive(r, c, visited)
    # Base Cases for recursion termination:
    # 1. Out of bounds?
    return false unless r.between?(0, @grid_height - 1) && c.between?(0, @grid_width - 1)
    # 2. Is it a wall?
    return false if @grid[r][c] == WALL
    # 3. Already visited in this path search?
    return false if visited.include?([r, c])
    # 4. Is it the end?
    if [r, c] == @end_pos
       return true # Found the end!
    end

    # Mark current cell as visited for this path attempt
    visited.add([r, c])

    # Mark current cell as part of the potential path (unless it's the Start)
    is_start = ([r, c] == @start_pos)
    original_char = @grid[r][c] # Store original character (might be PASSAGE or START)
    @grid[r][c] = PATH unless is_start

    # Explore neighbors (N, S, E, W) - Using grid coordinates directly
    DIRECTIONS.each_value do |dr, dc|
      nr, nc = r + dr, c + dc
      # Recursively try to solve from the neighbor
      if solve_recursive(nr, nc, visited)
        return true # Path found! Propagate success back up
      end
    end

    # If no neighbor led to the solution, this is a dead end.
    # Backtrack: restore the original character (PASSAGE or START)
    @grid[r][c] = original_char unless is_start
    # Note: We don't typically remove from `visited` in basic DFS,
    # as we only care about finding *one* path. If we needed all paths
    # or specific path properties, backtracking visited might be needed.

    return false # Path not found from this cell
  end

  public

  # --- Display ---

  def display
    @grid.each { |row| puts row.join('') }
  end
end

# --- Main Application Logic ---
if __FILE__ == $PROGRAM_NAME # Only run this if the script is executed directly
  puts "Welcome to the Maze Generator and Solver!"
  puts "-----------------------------------------"

  maze = nil

  loop do
    print "Choose action: [G]enerate new maze, [L]oad maze from file, [Q]uit: "
    choice = gets.chomp.upcase
    puts # Add a newline for readability

    case choice
    when 'G'
      width = 0
      while width <= 0
        print "Enter maze width (number of cells, > 0): "
        width = gets.chomp.to_i
        puts "Please enter a positive integer." if width <= 0
      end

      height = 0
      while height <= 0
        print "Enter maze height (number of cells, > 0): "
        height = gets.chomp.to_i
        puts "Please enter a positive integer." if height <= 0
      end

      begin
        maze = Maze.send(:new, width, height) # Call private constructor
        maze.generate
        puts "\nGenerated Maze (#{width}x#{height}):"
        maze.display

        # Ask to save
        print "\nSave generated maze to file? (y/n): "
        save_choice = gets.chomp.downcase
        if save_choice == 'y'
          print "Enter filename to save maze (e.g., my_maze.txt): "
          filename = gets.chomp
          if filename.empty?
            puts "Save cancelled (no filename provided)."
          else
            maze.save_to_file(filename) # Error handling is inside the method
          end
        end
        break # Exit loop after generation/save choice

      rescue ArgumentError => e
        puts "Error generating maze: #{e.message}"
        maze = nil # Reset maze object on error
      rescue => e
        puts "An unexpected error occurred during generation: #{e.message}"
        puts e.backtrace.join("\n")
        maze = nil
      end

    when 'L'
      print "Enter filename to load maze from: "
      filename = gets.chomp
      if filename.empty?
        puts "Load cancelled (no filename provided)."
        next # Go back to action choice
      end

      begin
        maze = Maze.load_from_file(filename)
        puts "\nMaze loaded successfully from #{filename}:"
        maze.display
        break # Exit loop after successful load
      rescue IOError, ArgumentError => e
        puts "Error loading maze: #{e.message}"
        maze = nil # Reset maze object
      rescue => e
        puts "An unexpected error occurred during loading: #{e.message}"
        puts e.backtrace.join("\n")
        maze = nil
      end

    when 'Q'
      puts "Goodbye!"
      exit
    else
      puts "Invalid choice. Please enter G, L, or Q."
    end
  end # end loop

  # --- Solving Stage (only if maze is available) ---
  if maze
    puts # Add spacing
    print "Do you want to solve this maze? (y/n): "
    solve_choice = gets.chomp.downcase

    if solve_choice == 'y'
      puts "\nSolving maze..."
      begin
        if maze.solve
          puts "Solved Maze:"
          maze.display
        else
          # This means the DFS couldn't reach E from S
          puts "Could not find a solution path from Start (S) to End (E)."
          puts "Check if S and E are connected by passages."
        end
      rescue StandardError => e # Catch errors during solving (e.g., missing S/E)
         puts "Error during solving: #{e.message}"
      rescue => e
         puts "An unexpected error occurred during solving: #{e.message}"
         puts e.backtrace.join("\n")
      end
    else
      puts "Okay, maze not solved."
    end
  else
    puts "\nNo maze loaded or generated to solve."
  end

end
