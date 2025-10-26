class_name Game2048
extends RefCounted

signal grid_changed(grid_data: Array[Array])
signal score_changed(new_score: int)
signal game_over()
signal game_won()
signal obstacles_spawned(obstacle_count: int)

const GRID_SIZE = 4

var grid: Array[Array] = []
var score: int = 0
var game_state: String = "playing"  # "playing", "won", "game_over"
var has_won: bool = false

# Game mode support
var current_mode = GameModeManager.GameMode.CLASSIC
var game_start_time: float = 0.0
var time_limit: float = 0.0
var moves_count: int = 0
var combo_count: int = 0
var last_move_time: float = 0.0
var obstacle_count: int = 0
var difficulty_level: int = 1

# Obstacle tiles (value -1 represents obstacle)
const OBSTACLE_TILE = -1

func _init(mode = GameModeManager.GameMode.CLASSIC):
	current_mode = mode
	setup_mode()
	initialize_grid()
	add_random_tile()
	add_random_tile()
	
	game_start_time = Time.get_ticks_msec() / 1000.0
	print("Game2048 initialized with mode: ", GameModeManager.get_mode_name(mode))

func initialize_grid():
	grid.clear()
	for i in range(GRID_SIZE):
		var row: Array = []
		for j in range(GRID_SIZE):
			row.append(0)
		grid.append(row)

func add_random_tile():
	var empty_cells = get_empty_cells()
	if empty_cells.is_empty():
		return false
	
	var random_cell = empty_cells[randi() % empty_cells.size()]
	var value = 2 if randf() < 0.9 else 4
	grid[random_cell.x][random_cell.y] = value
	
	# Check for achievements when new tiles are added
	check_tile_achievements()
	
	return true

func get_empty_cells() -> Array:
	var empty_cells: Array = []
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			if grid[i][j] == 0:
				empty_cells.append(Vector2i(i, j))
	return empty_cells

func is_obstacle(value: int) -> bool:
	return value == OBSTACLE_TILE

func can_move() -> bool:
	# Check for empty cells
	if not get_empty_cells().is_empty():
		return true
	
	# Check for possible merges
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			var current = grid[i][j]
			if current == OBSTACLE_TILE:
				continue
			# Check right
			if j < GRID_SIZE - 1 and grid[i][j + 1] == current:
				return true
			# Check down
			if i < GRID_SIZE - 1 and grid[i + 1][j] == current:
				return true
	
	return false

func move_left() -> bool:
	var moved = false
	var new_grid: Array[Array] = []
	var score_gained = 0
	
	# Initialize new grid
	for i in range(GRID_SIZE):
		var row: Array = []
		for j in range(GRID_SIZE):
			row.append(0)
		new_grid.append(row)
	
	for i in range(GRID_SIZE):
		var row = grid[i].duplicate()
		var merged_row = merge_line_left(row)
		new_grid[i] = merged_row.line
		if merged_row.moved:
			moved = true
		score_gained += merged_row.score_gained
	
	if moved:
		grid = new_grid
		add_random_tile()
		score += score_gained
		emit_signal("grid_changed", grid)
		emit_signal("score_changed", score)
		handle_move_completed(moved)
		check_game_state()
	
	return moved

func move_right() -> bool:
	var moved = false
	var new_grid: Array[Array] = []
	var score_gained = 0
	
	# Initialize new grid
	for i in range(GRID_SIZE):
		var row: Array = []
		for j in range(GRID_SIZE):
			row.append(0)
		new_grid.append(row)
	
	for i in range(GRID_SIZE):
		var row = grid[i].duplicate()
		row.reverse()
		var merged_row = merge_line_left(row)
		merged_row.line.reverse()
		new_grid[i] = merged_row.line
		if merged_row.moved:
			moved = true
		score_gained += merged_row.score_gained
	
	if moved:
		grid = new_grid
		add_random_tile()
		score += score_gained
		emit_signal("grid_changed", grid)
		emit_signal("score_changed", score)
		handle_move_completed(moved)
		check_game_state()
	
	return moved

func move_up() -> bool:
	var moved = false
	var new_grid: Array[Array] = []
	var score_gained = 0
	
	# Initialize new grid
	for i in range(GRID_SIZE):
		var row: Array = []
		for j in range(GRID_SIZE):
			row.append(0)
		new_grid.append(row)
	
	for j in range(GRID_SIZE):
		var column: Array = []
		for i in range(GRID_SIZE):
			column.append(grid[i][j])
		
		var merged_column = merge_line_left(column)
		for i in range(GRID_SIZE):
			new_grid[i][j] = merged_column.line[i]
		
		if merged_column.moved:
			moved = true
		score_gained += merged_column.score_gained
	
	if moved:
		grid = new_grid
		add_random_tile()
		score += score_gained
		emit_signal("grid_changed", grid)
		emit_signal("score_changed", score)
		handle_move_completed(moved)
		check_game_state()
	
	return moved

func move_down() -> bool:
	var moved = false
	var new_grid: Array[Array] = []
	var score_gained = 0
	
	# Initialize new grid
	for i in range(GRID_SIZE):
		var row: Array = []
		for j in range(GRID_SIZE):
			row.append(0)
		new_grid.append(row)
	
	for j in range(GRID_SIZE):
		var column: Array = []
		for i in range(GRID_SIZE):
			column.append(grid[i][j])
		
		column.reverse()
		var merged_column = merge_line_left(column)
		merged_column.line.reverse()
		
		for i in range(GRID_SIZE):
			new_grid[i][j] = merged_column.line[i]
		
		if merged_column.moved:
			moved = true
		score_gained += merged_column.score_gained
	
	if moved:
		grid = new_grid
		add_random_tile()
		score += score_gained
		emit_signal("grid_changed", grid)
		emit_signal("score_changed", score)
		handle_move_completed(moved)
		check_game_state()
	
	return moved

func merge_line_left(line: Array) -> Dictionary:
	var result: Array = []
	var score_gained = 0
	var moved = false
	
	# Remove zeros but keep obstacles
	var non_zero_values: Array = []
	var obstacle_positions: Array = []
	
	for idx in range(line.size()):
		if line[idx] == OBSTACLE_TILE:
			obstacle_positions.append(idx)
		elif line[idx] != 0:
			non_zero_values.append(line[idx])
	
	# Merge adjacent equal values (skip obstacles)
	var i = 0
	while i < non_zero_values.size():
		if i < non_zero_values.size() - 1 and non_zero_values[i] == non_zero_values[i + 1]:
			var merged_value = non_zero_values[i] * 2
			result.append(merged_value)
			score_gained += merged_value
			i += 2
		else:
			result.append(non_zero_values[i])
			i += 1
	
	# Fill with zeros and place obstacles
	var final_result = []
	var result_index = 0
	
	for j in range(GRID_SIZE):
		if obstacle_positions.has(j):
			final_result.append(OBSTACLE_TILE)
		elif result_index < result.size():
			final_result.append(result[result_index])
			result_index += 1
		else:
			final_result.append(0)
	
	# Check if anything moved
	for j in range(GRID_SIZE):
		if line[j] != final_result[j]:
			moved = true
			break
	
	return {
		"line": final_result,
		"moved": moved,
		"score_gained": score_gained
	}

func check_game_state():
	var win_condition = get_win_condition()
	
	# Check for win condition (only for modes that have win conditions)
	if not has_won and win_condition > 0:
		for i in range(GRID_SIZE):
			for j in range(GRID_SIZE):
				if grid[i][j] == win_condition:
					has_won = true
					game_state = "won"
					emit_signal("game_won")
					print("Game won! Reached tile: ", win_condition)
					return
	
	# Check for game over
	if not can_move():
		game_state = "game_over"
		emit_signal("game_over")
		print("Game over - no more moves available")

func restart():
	score = 0
	game_state = "playing"
	has_won = false
	moves_count = 0
	combo_count = 0
	obstacle_count = 0
	difficulty_level = 1
	initialize_grid()
	add_random_tile()
	add_random_tile()
	game_start_time = Time.get_ticks_msec() / 1000.0
	emit_signal("grid_changed", grid)
	emit_signal("score_changed", score)
	print("Game restarted")

func get_grid() -> Array:
	return grid

func get_score() -> int:
	return score

func get_game_state() -> String:
	return game_state

# Game mode setup and functionality
func setup_mode():
	# Set time limit for time attack mode
	if GameModeManager.has_time_limit(current_mode):
		time_limit = GameModeManager.get_time_limit(current_mode)
		print("Time limit set to: ", time_limit, " seconds")
	
	# Initialize mode-specific variables
	moves_count = 0
	combo_count = 0
	obstacle_count = 0
	difficulty_level = 1

func get_win_condition() -> int:
	var win_condition = GameModeManager.get_win_condition(current_mode)
	if win_condition > 0:
		return win_condition
	else:
		return 2048  # Default

func update_mode_logic():
	var current_time = Time.get_ticks_msec() / 1000.0
	
	match current_mode:
		GameModeManager.GameMode.TIME_ATTACK:
			update_time_attack_logic(current_time)
		GameModeManager.GameMode.SURVIVAL:
			update_survival_logic(current_time)

func update_time_attack_logic(current_time: float):
	if time_limit > 0:
		var elapsed_time = current_time - game_start_time
		var time_left = time_limit - elapsed_time
		
		if time_left <= 0:
			# Time's up!
			game_state = "game_over"
			emit_signal("game_over")
			print("Time's up! Game over")
			return

		if GameModeManager.has_special_rule("combo_multiplier", current_mode):
			if current_time - last_move_time < 2.0:  # Quick move within 2 seconds
				combo_count += 1
			else:
				combo_count = 0
	
	last_move_time = current_time
	
	last_move_time = current_time

func update_survival_logic(current_time: float):
	# Increase difficulty over time
	if GameModeManager.has_special_rule("increasing_difficulty", current_mode):
		var minutes_played = (current_time - game_start_time) / 60.0
		difficulty_level = int(minutes_played) + 1
	
	# Spawn obstacles based on moves and difficulty
	if GameModeManager.spawns_obstacles(current_mode) and moves_count > 5:
		var obstacle_frequency = GameModeManager.get_obstacle_frequency(current_mode)
		obstacle_frequency *= difficulty_level  # Increase with difficulty
		
		if randf() < obstacle_frequency:
			spawn_obstacle()

func spawn_obstacle():
	var empty_cells = get_empty_cells()
	if empty_cells.is_empty():
		return
	
	var obstacle_cell = empty_cells[randi() % empty_cells.size()]
	grid[obstacle_cell.x][obstacle_cell.y] = OBSTACLE_TILE
	obstacle_count += 1
	
	emit_signal("obstacles_spawned", obstacle_count)
	emit_signal("grid_changed", grid)  # Update grid to show obstacle
	print("Obstacle spawned at: ", obstacle_cell, " Total obstacles: ", obstacle_count)

func calculate_mode_score_bonus(base_score: int) -> int:
	var bonus = 0
	
	match current_mode:
		GameModeManager.GameMode.TIME_ATTACK:
			if GameModeManager.has_special_rule("bonus_scoring", current_mode):
				# Quick move bonus
				if combo_count > 0:
					bonus += base_score * combo_count * 0.1  # 10% bonus per combo
			
			if GameModeManager.has_special_rule("combo_multiplier", current_mode):
				if combo_count >= 3:
					bonus += base_score * 0.5  # 50% bonus for 3+ combos
		
		GameModeManager.GameMode.SURVIVAL:
			# Survival bonus based on difficulty level
			bonus += base_score * (difficulty_level - 1) * 0.2  # 20% bonus per difficulty level
	
	return int(bonus)

func handle_move_completed(moved: bool):
	if moved:
		moves_count += 1
		update_mode_logic()
		print("Move ", moves_count, " completed")

# Achievement checking functions
func check_tile_achievements():
	var highest_tile = get_highest_tile_value()
	
	# Check for tile-based achievements
	if SaveManager:
		if highest_tile >= 128:
			SaveManager.unlock_achievement("reach_128")
		if highest_tile >= 256:
			SaveManager.unlock_achievement("reach_256")
		if highest_tile >= 512:
			SaveManager.unlock_achievement("reach_512")
		if highest_tile >= 1024:
			SaveManager.unlock_achievement("reach_1024")
		if highest_tile >= 2048:
			SaveManager.unlock_achievement("reach_2048")

func get_highest_tile_value() -> int:
	var highest = 0
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			var cell_value = grid[i][j]
			if cell_value > highest and cell_value != OBSTACLE_TILE:
				highest = cell_value
	return highest

func check_score_achievements():
	if SaveManager:
		if score >= 1000:
			SaveManager.unlock_achievement("score_1000")
		if score >= 5000:
			SaveManager.unlock_achievement("score_5000")
		if score >= 10000:
			SaveManager.unlock_achievement("score_10000")

func check_mode_specific_achievements(won: bool):
	if not SaveManager:
		return
	
	match current_mode:
		GameModeManager.GameMode.TIME_ATTACK:
			if won:
				SaveManager.unlock_achievement("time_master")
				# Check time remaining for fast_thinker
				var current_time = Time.get_ticks_msec() / 1000.0
				var time_used = current_time - game_start_time
				var time_left = time_limit - time_used
				if time_left >= 30:
					SaveManager.unlock_achievement("fast_thinker")
		
		GameModeManager.GameMode.SURVIVAL:
			if moves_count >= 100:
				SaveManager.unlock_achievement("survivor")
			if moves_count >= 300:
				SaveManager.unlock_achievement("endurance_champ")
			if get_highest_tile_value() >= 512 and obstacle_count >= 5:
				SaveManager.unlock_achievement("obstacle_master")

func finalize_game_session(won: bool):
	# Update statistics and check achievements
	if SaveManager:
		var highest_tile = get_highest_tile_value()
		var play_time = (Time.get_ticks_msec() / 1000.0) - game_start_time
		
		SaveManager.update_game_finished(score, highest_tile, moves_count, won)
		SaveManager.update_play_time(play_time)
		
		# Check all types of achievements
		check_tile_achievements()
		check_score_achievements()
		check_mode_specific_achievements(won)
		
		# First game achievement
		if SaveManager.get_total_games_played() == 1:
			SaveManager.unlock_achievement("first_game")
		
		# Efficiency achievements
		if won and moves_count <= 200:
			SaveManager.unlock_achievement("efficient_win")
		if won and moves_count <= 150:
			SaveManager.unlock_achievement("speed_demon")
		
		print("Game session finalized - Score: ", score, " Highest Tile: ", highest_tile, " Moves: ", moves_count)

# Utility functions
func get_grid_size() -> int:
	return GRID_SIZE

func get_moves_count() -> int:
	return moves_count

func get_obstacle_count() -> int:
	return obstacle_count

func get_difficulty_level() -> int:
	return difficulty_level

func get_time_remaining() -> float:
	if time_limit > 0:
		var current_time = Time.get_ticks_msec() / 1000.0
		var elapsed_time = current_time - game_start_time
		return max(0, time_limit - elapsed_time)
	return 0.0

# Debug functions
func print_grid():
	print("=== Current Grid ===")
	for i in range(GRID_SIZE):
		var row_str = ""
		for j in range(GRID_SIZE):
			row_str += str(grid[i][j]) + "\t"
		print(row_str)
	print("===================")

func get_game_stats() -> Dictionary:
	return {
		"score": score,
		"moves": moves_count,
		"highest_tile": get_highest_tile_value(),
		"obstacles": obstacle_count,
		"difficulty": difficulty_level,
		"game_state": game_state,
		"time_remaining": get_time_remaining(),
		"mode": GameModeManager.get_mode_name(current_mode)
	}
