#! /usr/bin/env elixir

defmodule State do
  # each room is vertical
  defstruct hallway: [0, 0, 0, 0, 0, 0, 0],
            rooms: [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]

  @symbols %{
    "." => 0,
    "A" => 1,
    "B" => 2,
    "C" => 3,
    "D" => 4
  }

  def new() do
    %State{}
  end

  def new(raw_str) do
    [_header, _raw_hallway, raw_room1, raw_room2, _footer, _newline] = String.split(raw_str, "\n")
    hallway = List.duplicate(0, 7)

    rooms =
      [
        Enum.map(Range.new(3, 9, 2), &@symbols[String.at(raw_room1, &1)]),
        # additional rows given in problem description
        [4, 3, 2, 1],
        [4, 2, 1, 3],
        Enum.map(Range.new(3, 9, 2), &@symbols[String.at(raw_room2, &1)])
      ]
      |> Enum.zip()
      |> Enum.map(&Tuple.to_list(&1))

    %State{hallway: hallway, rooms: rooms}
  end

  def goal() do
    %State{
      hallway: [0, 0, 0, 0, 0, 0, 0],
      rooms: [
        [1, 1, 1, 1],
        [2, 2, 2, 2],
        [3, 3, 3, 3],
        [4, 4, 4, 4]
      ]
    }
  end

  def cost_of_cell(cell) do
    case cell do
      1 -> 1
      2 -> 10
      3 -> 100
      4 -> 1000
    end
  end

  def room_top(state, room_id) do
    state.rooms
    |> Enum.at(room_id - 1, [])
    |> Enum.find(0, &(&1 > 0))
  end

  def room_occupancy(state, room_id) do
    state.rooms
    |> Enum.at(room_id - 1, [])
    |> Enum.count(&(&1 > 0))
  end

  # Check if can move from a room (1-4) to a hallway (0-6)
  def can_move_to_hallway(state, from, to) do
    unless 1 <= from and from <= 4 and 0 <= to and to <= 6 do
      raise "Invalid room/hallway id"
    end

    # the range covers part of hallway that move passes through
    range =
      if to * 2 < from * 2 + 1 do
        # move left from room to hallway
        to..from
      else
        # move right from room to hallway
        (from + 1)..to
      end

    range_clear =
      state.hallway
      |> Enum.slice(range)
      |> Enum.all?(&(&1 == 0))

    # destination hallway is clear
    dest_clear = Enum.at(state.hallway, to, 0) == 0

    # can only move if room isn't empty
    room_not_clear = room_occupancy(state, from) > 0

    # cannot move out of correct room if entire room is correct
    is_room_not_all_correct =
      !(state.rooms
        |> Enum.at(from - 1, [])
        |> Enum.all?(&(&1 == from or &1 == 0)))

    range_clear and dest_clear and room_not_clear and is_room_not_all_correct
  end

  def can_move_to_room(state, from, to) do
    unless 1 <= to and to <= 4 and 0 <= from and from <= 6 do
      raise "Invalid room/hallway id"
    end

    cell = state.hallway |> Enum.at(from, 0)

    # room is not full
    has_space = State.room_occupancy(state, to) < 4

    # check that the hallway that the move passes through is clear
    # check is only necessary if more than 1 cell away
    range =
      cond do
        # move left from room to hallway
        (from + 1) * 2 < to * 2 + 1 ->
          Enum.slice(state.hallway, (from + 1)..to)

        # move right from room to hallway
        (from - 1) * 2 > to * 2 + 1 ->
          Enum.slice(state.hallway, (to + 1)..(from - 1))

        # check is only necessary if more than 1 cell away
        # otherwise, no need to check anything
        true ->
          []
      end

    range_clear =
      range
      |> Enum.all?(&(&1 == 0))

    # can only move to room if it is correct number ...
    is_correct_number = cell == to

    # ... and the room only has correct numbered cells
    is_room_all_correct =
      state.rooms
      |> Enum.at(to - 1, [])
      |> Enum.all?(&(&1 == to or &1 == 0))

    has_space and is_correct_number and is_room_all_correct and range_clear
  end

  # Move from room to hallway, returning new state and cost of move
  def move_to_hallway(state, from, to) do
    unless can_move_to_hallway(state, from, to) do
      raise "Cannot move from room #{from} to hallway #{to}"
    end

    # remove the cell from the room
    new_rooms =
      state.rooms
      |> Enum.with_index()
      |> Enum.map(fn {room, idx} ->
        if idx == from - 1 do
          room
          |> Enum.reduce({[], false}, fn r, {acc, done} ->
            if done do
              {[r | acc], true}
            else
              if r == 0 do
                {[r | acc], false}
              else
                {[0 | acc], true}
              end
            end
          end)
          |> elem(0)
          |> Enum.reverse()
        else
          room
        end
      end)

    removed_cell = State.room_top(state, from)

    # add the cell to the hallway
    new_hallway =
      state.hallway
      |> Enum.with_index()
      |> Enum.map(fn {h, idx} ->
        if idx == to do
          removed_cell
        else
          h
        end
      end)

    new_state = %State{
      hallway: new_hallway,
      rooms: new_rooms
    }

    # need to calculate distance with new state since we need the removed room
    # spot empty
    distance = State.count_moves(new_state, to, from)
    cost = State.cost_of_cell(removed_cell) * distance
    {new_state, cost}
  end

  # Move from hallway to room, returning new state and cost of move
  def move_to_room(state, from, to) do
    unless can_move_to_room(state, from, to) do
      raise "Cannot move from hallway #{from} to room #{to}"
    end

    removed_cell =
      state.hallway
      |> Enum.at(from, 0)

    distance = State.count_moves(state, from, to)
    cost = State.cost_of_cell(removed_cell) * distance

    # remove the cell from the hallway
    new_hallway =
      state.hallway
      |> Enum.with_index()
      |> Enum.map(fn {h, idx} ->
        if idx == from do
          0
        else
          h
        end
      end)

    # add the cell to the room
    new_rooms =
      state.rooms
      |> Enum.with_index()
      |> Enum.map(fn {room, idx} ->
        if idx == to - 1 do
          # position of first empty cell
          {_, first_empty} =
            room
            |> Enum.with_index()
            |> Enum.reverse()
            |> Enum.find(0, fn {r, _} -> r == 0 end)

          room
          |> Enum.with_index()
          |> Enum.map(fn {r, i} ->
            if i == first_empty do
              removed_cell
            else
              r
            end
          end)
        else
          room
        end
      end)

    {%{state | hallway: new_hallway, rooms: new_rooms}, cost}
  end

  # Count moves from hallway to room, not including any non-zero cells in the
  # room
  def count_moves(state, hallway, room) do
    unless 1 <= room and room <= 4 and 0 <= hallway and hallway <= 6 do
      raise "Invalid room/hallway id"
    end

    hallway_n =
      cond do
        hallway == 0 ->
          0

        hallway == 6 ->
          10

        true ->
          hallway * 2 - 1
      end

    room_n = room * 2
    hallway_moves = abs(hallway_n - room_n)

    room_moves =
      state.rooms
      |> Enum.at(room - 1, [])
      |> Enum.count(&(&1 == 0))

    hallway_moves + room_moves
  end

  # Find all the states that can be reached from the given state.
  # Returns list of tuples of the new state and the cost of the move.
  def neighbors(state) do
    # try all moves from room to hallway
    room_to_hallway =
      Enum.flat_map(0..6, fn h ->
        1..4
        |> Enum.filter(&State.can_move_to_hallway(state, &1, h))
        |> Enum.map(&State.move_to_hallway(state, &1, h))
      end)

    # try all moves from hallway to room
    hallway_to_room =
      Enum.flat_map(0..6, fn h ->
        1..4
        |> Enum.filter(&State.can_move_to_room(state, h, &1))
        |> Enum.map(&State.move_to_room(state, h, &1))
      end)

    room_to_hallway ++ hallway_to_room
  end
end

defimpl String.Chars, for: State do
  @symbols %{
    0 => ".",
    1 => "A",
    2 => "B",
    3 => "C",
    4 => "D"
  }
  def to_string(state) do
    header = "###############"

    hallway = "#" <> Enum.map_join(state.hallway, ".", &@symbols[&1]) <> "#"

    rooms =
      state.rooms
      |> Enum.zip()
      |> Enum.map(fn room_row ->
        line_symbols =
          room_row
          |> Tuple.to_list()
          |> Enum.map_join("#", &@symbols[&1])

        "####" <> line_symbols <> "####"
      end)

    footer = "###############"

    total = [header, hallway] ++ rooms ++ [footer, ""]
    Enum.join(total, "\n")
  end
end

# Priority queue (min-heap implemented as sorted list)
defmodule PQ do
  defstruct contents: []

  def new() do
    %PQ{contents: []}
  end

  def add(pq, {item, priority}) do
    idx =
      pq.contents
      |> Enum.find_index(fn {_item, p} -> priority < p end) ||
        -1

    new_contents =
      pq.contents
      |> List.insert_at(idx, {item, priority})

    %PQ{contents: new_contents}
  end

  # Returns the lowest priority item
  def peek(pq) do
    case pq.contents do
      [{item, _priority} | _] -> item
      [] -> nil
    end
  end

  # Removes the lowest priority item, returning the new queue and the item
  def pop(pq) do
    case pq.contents do
      [{item, _priority} | tail] ->
        {%PQ{contents: tail}, item}

      [] ->
        {pq, nil}
    end
  end

  def empty?(pq) do
    Enum.empty?(pq.contents)
  end
end

defmodule Dijkstra do
  @max_cost 1_000_000_000

  def find(start, goal) do
    # initialize the queue with the start state
    queue =
      PQ.new()
      |> PQ.add({start, 0})

    visited = %{start => 0}

    result = Dijkstra.dijkstra(visited, queue)
    result[goal]
  end

  def dijkstra(visited, pq) do
    if PQ.empty?(pq) do
      # base case: we are done
      visited
    else
      {pq, cur} = PQ.pop(pq)
      cur_cost = visited[cur]
      neighbors = State.neighbors(cur)

      {visited, pq} =
        neighbors
        |> Enum.reduce({visited, pq}, fn {state, cost}, {visited_, pq_} ->
          total_cost = cost + cur_cost
          old_cost = visited_[state] || @max_cost

          # if we can do better, update cost
          if total_cost < old_cost do
            visited_ = Map.put(visited_, state, total_cost)
            pq_ = PQ.add(pq_, {state, total_cost})
            {visited_, pq_}
          else
            {visited_, pq_}
          end
        end)

      Dijkstra.dijkstra(visited, pq)
      # visited
    end
  end
end

{:ok, str} = File.read("input.txt")
s = State.new(str)

goal = State.goal()
IO.puts(Dijkstra.find(s, goal))
