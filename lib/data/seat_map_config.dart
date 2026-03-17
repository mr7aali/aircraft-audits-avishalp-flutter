/// One block of consecutive rows with the same column layout.
class SeatMapBlock {
  const SeatMapBlock({
    required this.startRow,
    required this.endRow,
    required this.columns,
  });
  final int startRow;
  final int endRow;
  final List<String> columns;
}

/// One section (e.g. "First Class") with one or more blocks.
class SeatMapSection {
  const SeatMapSection({
    required this.title,
    required this.blocks,
  });
  final String title;
  final List<SeatMapBlock> blocks;
}

/// Full seat map layout for an aircraft.
class SeatMapConfig {
  const SeatMapConfig({required this.sections});
  final List<SeatMapSection> sections;
}

/// Aircraft identifier → seat map config.
/// Used to switch seat map when "Type of aircraft" changes.
final Map<String, SeatMapConfig> seatMapByAircraft = {
  'Boeing 757-300 (75Y)': SeatMapConfig(
    sections: [
      SeatMapSection(
        title: 'First Class',
        blocks: [
          SeatMapBlock(startRow: 1, endRow: 6, columns: ['A', 'B', 'C', 'D']),
        ],
      ),
      SeatMapSection(
        title: 'Delta Comfort / Main',
        blocks: [
          SeatMapBlock(startRow: 14, endRow: 20, columns: ['A', 'B', 'C', 'D', 'E', 'F']),
          SeatMapBlock(startRow: 21, endRow: 40, columns: ['A', 'B', 'C', 'D', 'E', 'F']),
        ],
      ),
      SeatMapSection(
        title: 'Rear Cabin',
        blocks: [
          SeatMapBlock(startRow: 41, endRow: 49, columns: ['A', 'B', 'C', 'D', 'E', 'F']),
        ],
      ),
    ],
  ),
  'Boeing 737-800': SeatMapConfig(
    sections: [
      SeatMapSection(
        title: 'First Class',
        blocks: [
          SeatMapBlock(startRow: 1, endRow: 5, columns: ['A', 'B', 'C', 'D']),
        ],
      ),
      SeatMapSection(
        title: 'Main Cabin',
        blocks: [
          SeatMapBlock(startRow: 6, endRow: 20, columns: ['A', 'B', 'C', 'D', 'E', 'F']),
          SeatMapBlock(startRow: 21, endRow: 33, columns: ['A', 'B', 'C', 'D', 'E', 'F']),
        ],
      ),
      SeatMapSection(
        title: 'Rear Cabin',
        blocks: [
          SeatMapBlock(startRow: 34, endRow: 39, columns: ['A', 'B', 'C', 'D', 'E', 'F']),
        ],
      ),
    ],
  ),
  'Airbus A320': SeatMapConfig(
    sections: [
      SeatMapSection(
        title: 'First Class',
        blocks: [
          SeatMapBlock(startRow: 1, endRow: 4, columns: ['A', 'B', 'C']),
        ],
      ),
      SeatMapSection(
        title: 'Main Cabin',
        blocks: [
          SeatMapBlock(startRow: 5, endRow: 18, columns: ['A', 'B', 'C', 'D', 'E', 'F']),
          SeatMapBlock(startRow: 19, endRow: 29, columns: ['A', 'B', 'C', 'D', 'E', 'F']),
        ],
      ),
      SeatMapSection(
        title: 'Rear Cabin',
        blocks: [
          SeatMapBlock(startRow: 30, endRow: 35, columns: ['A', 'B', 'C', 'D', 'E', 'F']),
        ],
      ),
    ],
  ),
};
